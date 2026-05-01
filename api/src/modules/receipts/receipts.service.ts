import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  ReceiptStatus,
  TransactionType,
  TransactionSource,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { TransactionCreatedEvent } from '../../common/events/transaction.events';
import { ReceiptParserService } from './receipt-parser.service';
import { ScanReceiptDto } from './dto/scan-receipt.dto';
import { ConfirmReceiptDto } from './dto/confirm-receipt.dto';
import { UpdateReceiptDto } from './dto/update-receipt.dto';

@Injectable()
export class ReceiptsService {
  private readonly logger = new Logger(ReceiptsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly parser: ReceiptParserService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async findAll(userId: string, status?: ReceiptStatus, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const where: any = { userId };
    if (status) where.status = status;

    const [receipts, total] = await Promise.all([
      this.prisma.receipt.findMany({
        where,
        include: { items: { orderBy: { sortOrder: 'asc' } } },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.receipt.count({ where }),
    ]);

    return {
      data: receipts.map(this.format),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async findOne(userId: string, id: string) {
    return this.format(await this.findOwned(userId, id));
  }

  async scan(userId: string, dto: ScanReceiptDto, imageUrl: string) {
    let parsed: { amount: number | null; merchant: string | null; date: Date | null; tax: number | null; paymentMethod: string | null; items: any[]; confidence: number } = { amount: null, merchant: null, date: null, tax: null, paymentMethod: null, items: [], confidence: 0 };
    let rawText = dto.rawText ?? null;
    let ocrSource = 'CLIENT';

    // Client OCR text geldiyse parse et
    if (rawText) {
      parsed = this.parser.parse(rawText);
      // Güven skoru düşükse backend OCR tetiklenebilir (şimdilik stub)
      if ((dto.confidence ?? parsed.confidence) < 0.5) {
        this.logger.warn(`Düşük OCR güveni: ${dto.confidence} — Cloud Vision TODO`);
        ocrSource = 'CLIENT_LOW_CONFIDENCE';
      }
    } else {
      // Sadece görsel yüklendi, Cloud Vision TODO
      this.logger.warn(`Raw text yok — Cloud Vision entegrasyonu henüz yok`);
      ocrSource = 'NONE';
    }

    // Mükerrer fiş kontrolü (7 gün içinde aynı tutar + tarih + işyeri)
    if (parsed.amount && parsed.date && parsed.merchant) {
      const sevenDaysAgo = new Date(parsed.date);
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
      const duplicate = await this.prisma.receipt.findFirst({
        where: {
          userId,
          parsedAmount: parsed.amount,
          parsedMerchant: { contains: parsed.merchant.slice(0, 20) },
          parsedDate: { gte: sevenDaysAgo },
          status: { not: ReceiptStatus.FAILED },
        },
      });
      if (duplicate) {
        throw new BadRequestException({
          message: 'Benzer bir fiş zaten mevcut',
          duplicateReceiptId: duplicate.id,
        });
      }
    }

    const receipt = await this.prisma.receipt.create({
      data: {
        userId,
        imageUrl,
        ocrRawText: rawText,
        ocrSource,
        confidence: parsed.confidence,
        parsedAmount: parsed.amount,
        parsedMerchant: parsed.merchant,
        parsedDate: parsed.date,
        parsedTax: parsed.tax,
        paymentMethod: parsed.paymentMethod,
        status: rawText ? ReceiptStatus.PARSED : ReceiptStatus.PROCESSING,
        ...(parsed.items.length > 0 && {
          items: {
            create: parsed.items.map((item, i) => ({
              name: item.name,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              totalPrice: item.totalPrice,
              sortOrder: i,
            })),
          },
        }),
      },
      include: { items: { orderBy: { sortOrder: 'asc' } } },
    });

    // Akıllı kategori önerisi
    const suggestedCategory = parsed.merchant
      ? await this.suggestCategory(userId, parsed.merchant)
      : null;

    return { ...this.format(receipt), suggestedCategory };
  }

  async update(userId: string, id: string, dto: UpdateReceiptDto) {
    await this.findOwned(userId, id);

    return this.format(
      await this.prisma.receipt.update({
        where: { id },
        data: {
          ...(dto.parsedAmount !== undefined && { parsedAmount: dto.parsedAmount }),
          ...(dto.parsedMerchant !== undefined && { parsedMerchant: dto.parsedMerchant }),
          ...(dto.parsedDate !== undefined && { parsedDate: new Date(dto.parsedDate) }),
          ...(dto.parsedTax !== undefined && { parsedTax: dto.parsedTax }),
          ...(dto.paymentMethod !== undefined && { paymentMethod: dto.paymentMethod }),
        },
        include: { items: { orderBy: { sortOrder: 'asc' } } },
      }),
    );
  }

  async confirm(userId: string, id: string, dto: ConfirmReceiptDto) {
    const receipt = await this.findOwned(userId, id);

    if (receipt.status === ReceiptStatus.CONFIRMED) {
      throw new BadRequestException('Bu fiş zaten onaylandı');
    }

    const amount = dto.amount ?? Number(receipt.parsedAmount);
    if (!amount || amount <= 0) {
      throw new BadRequestException('Geçerli bir tutar bulunamadı');
    }

    const transactionDate = dto.transactionDate
      ? new Date(dto.transactionDate)
      : receipt.parsedDate ?? new Date();

    const result = await this.prisma.$transaction(async (tx) => {
      await tx.account.update({
        where: { id: dto.accountId },
        data: { balance: { decrement: amount } },
      });

      const transaction = await tx.transaction.create({
        data: {
          userId,
          accountId: dto.accountId,
          categoryId: dto.categoryId ?? null,
          type: TransactionType.EXPENSE,
          source: TransactionSource.MANUAL,
          amount,
          title: dto.merchant ?? receipt.parsedMerchant ?? 'Fiş İşlemi',
          note: dto.note ?? null,
          transactionDate,
        },
      });

      await tx.receipt.update({
        where: { id },
        data: { status: ReceiptStatus.CONFIRMED, transactionId: transaction.id },
      });

      return transaction;
    });

    // Merchant → category mapping güncelle
    if (dto.categoryId && (dto.merchant ?? receipt.parsedMerchant)) {
      const merchantKey = this.normalizeMerchant(dto.merchant ?? receipt.parsedMerchant ?? '');
      await this.upsertMerchantMapping(userId, merchantKey, dto.categoryId);
    }

    this.eventEmitter.emit(
      'transaction.created',
      new TransactionCreatedEvent(
        result.id,
        userId,
        dto.categoryId ?? null,
        TransactionType.EXPENSE,
        TransactionSource.MANUAL,
        amount,
        transactionDate,
      ),
    );

    return { message: 'Fiş onaylandı', transactionId: result.id };
  }

  async remove(userId: string, id: string) {
    await this.findOwned(userId, id);
    await this.prisma.receipt.delete({ where: { id } });
    return { message: 'Fiş silindi' };
  }

  async getMerchantMappings(userId: string) {
    return this.prisma.merchantCategoryMap.findMany({
      where: { OR: [{ userId }, { userId: null }] },
      include: { category: true },
      orderBy: { hitCount: 'desc' },
    });
  }

  async upsertMerchantMapping(userId: string, merchantKey: string, categoryId: string) {
    const key = this.normalizeMerchant(merchantKey);
    const existing = await this.prisma.merchantCategoryMap.findFirst({
      where: { userId, merchantKey: key },
    });

    if (existing) {
      return this.prisma.merchantCategoryMap.update({
        where: { id: existing.id },
        data: { categoryId, hitCount: { increment: 1 } },
      });
    }

    return this.prisma.merchantCategoryMap.create({
      data: { userId, merchantKey: key, categoryId, hitCount: 1 },
    });
  }

  private async suggestCategory(userId: string, merchant: string) {
    const key = this.normalizeMerchant(merchant);

    // Önce kullanıcı mapping'i
    const userMapping = await this.prisma.merchantCategoryMap.findFirst({
      where: { userId, merchantKey: { contains: key.slice(0, 15) } },
      include: { category: true },
      orderBy: { hitCount: 'desc' },
    });
    if (userMapping) return userMapping.category;

    // Global mapping
    const globalMapping = await this.prisma.merchantCategoryMap.findFirst({
      where: { userId: null, merchantKey: { contains: key.slice(0, 15) } },
      include: { category: true },
      orderBy: { hitCount: 'desc' },
    });
    return globalMapping?.category ?? null;
  }

  private normalizeMerchant(name: string): string {
    return name
      .toLowerCase()
      .replace(/a\.ş\.|ltd\.|tic\.|\s+/g, ' ')
      .trim()
      .slice(0, 100);
  }

  private async findOwned(userId: string, id: string) {
    const receipt = await this.prisma.receipt.findFirst({
      where: { id, userId },
      include: { items: { orderBy: { sortOrder: 'asc' } } },
    });
    if (!receipt) throw new NotFoundException('Fiş bulunamadı');
    return receipt;
  }

  private format(r: any) {
    return {
      ...r,
      parsedAmount: r.parsedAmount !== null ? Number(r.parsedAmount) : null,
      parsedTax: r.parsedTax !== null ? Number(r.parsedTax) : null,
      confidence: r.confidence !== null ? Number(r.confidence) : null,
      items: r.items?.map((i: any) => ({
        ...i,
        unitPrice: Number(i.unitPrice),
        totalPrice: Number(i.totalPrice),
      })),
    };
  }
}
