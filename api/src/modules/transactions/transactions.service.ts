/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-argument */
import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  AccountType,
  TransactionSource,
  TransactionType,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { BalanceService } from '../../common/services/balance.service';
import {
  TransactionCreatedEvent,
  TransactionUpdatedEvent,
  TransactionDeletedEvent,
} from '../../common/events/transaction.events';
import { advanceByFrequency } from '../../common/utils/frequency.utils';
import { CreateTransactionDto } from './dto/create-transaction.dto';
import { UpdateTransactionDto } from './dto/update-transaction.dto';
import { QueryTransactionDto } from './dto/query-transaction.dto';

@Injectable()
export class TransactionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly balanceService: BalanceService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async findAll(userId: string, query: QueryTransactionDto) {
    const {
      page = 1,
      limit = 20,
      type,
      accountId,
      categoryId,
      sharedBudgetId,
      startDate,
      endDate,
      search,
    } = query;
    const skip = (page - 1) * limit;

    const where: any = { userId };
    if (type) where.type = type;
    if (accountId) where.accountId = accountId;
    if (categoryId) where.categoryId = categoryId;
    // 'null' string'i = sharedBudgetId IS NULL (kişisel-only liste).
    // Boş gelirse filtre uygulanmaz, ortak+kişisel hepsi gelir.
    if (sharedBudgetId !== undefined) {
      where.sharedBudgetId = sharedBudgetId === 'null' ? null : sharedBudgetId;
    }
    if (startDate || endDate) {
      where.transactionDate = {};
      if (startDate) where.transactionDate.gte = new Date(startDate);
      if (endDate) where.transactionDate.lte = new Date(endDate);
    }
    if (search) {
      where.OR = [
        { title: { contains: search } },
        { description: { contains: search } },
      ];
    }

    const [transactions, total] = await Promise.all([
      this.prisma.transaction.findMany({
        where,
        include: {
          category: true,
          account: {
            select: {
              id: true,
              name: true,
              icon: true,
              color: true,
              type: true,
            },
          },
          transferToAccount: {
            select: { id: true, name: true, icon: true, color: true },
          },
          tags: { include: { tag: true } },
        },
        orderBy: { transactionDate: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.transaction.count({ where }),
    ]);

    return {
      data: transactions.map((t) => this.format(t)),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getSummary(
    userId: string,
    query: Pick<QueryTransactionDto, 'startDate' | 'endDate' | 'accountId'>,
  ) {
    const where: any = { userId };
    if (query.accountId) where.accountId = query.accountId;
    if (query.startDate || query.endDate) {
      where.transactionDate = {};
      if (query.startDate)
        where.transactionDate.gte = new Date(query.startDate);
      if (query.endDate) where.transactionDate.lte = new Date(query.endDate);
    }

    const [incomeAgg, expenseAgg] = await Promise.all([
      this.prisma.transaction.aggregate({
        where: { ...where, type: TransactionType.INCOME },
        _sum: { amount: true },
      }),
      this.prisma.transaction.aggregate({
        where: { ...where, type: TransactionType.EXPENSE },
        _sum: { amount: true },
      }),
    ]);

    const income = Number(incomeAgg._sum.amount ?? 0);
    const expense = Number(expenseAgg._sum.amount ?? 0);

    return { income, expense, net: income - expense };
  }

  async findOne(userId: string, id: string) {
    const transaction = await this.prisma.transaction.findFirst({
      where: { id, userId },
      include: {
        category: true,
        account: true,
        transferToAccount: true,
        tags: { include: { tag: true } },
      },
    });

    if (!transaction) throw new NotFoundException('İşlem bulunamadı');
    return this.format(transaction);
  }

  async create(userId: string, dto: CreateTransactionDto) {
    if (dto.type === TransactionType.TRANSFER && !dto.transferToAccountId) {
      throw new BadRequestException(
        'Transfer işlemi için hedef hesap gereklidir',
      );
    }

    if (dto.type === TransactionType.INCOME) {
      const account = await this.prisma.account.findFirst({
        where: { id: dto.accountId, userId },
        select: { type: true },
      });
      if (account?.type === AccountType.CREDIT_CARD) {
        throw new BadRequestException(
          'Kredi kartı hesabına gelir kaydedilemez. Kart borcu kapatmak için hesaplar arası transfer kullanın.',
        );
      }
    }

    const transactionDate = dto.transactionDate
      ? new Date(dto.transactionDate)
      : new Date();

    // İşlemi ve bakiye güncellemesini atomik yap
    const transaction = await this.prisma.$transaction(async (tx) => {
      const created = await tx.transaction.create({
        data: {
          userId,
          accountId: dto.accountId,
          categoryId: dto.categoryId ?? null,
          type: dto.type,
          amount: dto.amount,
          title: dto.title,
          note: dto.note ?? null,
          transactionDate,
          transferToAccountId: dto.transferToAccountId ?? null,
          sharedBudgetId: dto.sharedBudgetId ?? null,
          ...(dto.tagIds?.length && {
            tags: {
              create: dto.tagIds.map((tagId) => ({ tagId })),
            },
          }),
        },
        include: {
          category: true,
          account: {
            select: {
              id: true,
              name: true,
              icon: true,
              color: true,
              type: true,
            },
          },
          transferToAccount: {
            select: { id: true, name: true, icon: true, color: true },
          },
          tags: { include: { tag: true } },
        },
      });

      // Bakiyeyi güncelle
      await this.balanceService.apply(
        tx,
        dto.accountId,
        dto.type,
        dto.amount,
        dto.transferToAccountId ?? undefined,
      );

      return created;
    });

    // Tekrarlayan işlem şablonu oluştur
    if (dto.isRecurring && dto.frequency) {
      await this.createRecurringTemplate(userId, dto, transactionDate);
    }

    // Event emit et (Budget, vs. dinler)
    this.eventEmitter.emit(
      'transaction.created',
      new TransactionCreatedEvent(
        transaction.id,
        userId,
        dto.accountId,
        dto.categoryId ?? null,
        dto.type,
        'MANUAL',
        dto.amount,
        transactionDate,
        dto.sharedBudgetId ?? null,
      ),
    );

    return this.format(transaction);
  }

  async update(userId: string, id: string, dto: UpdateTransactionDto) {
    const existing = await this.prisma.transaction.findFirst({
      where: { id, userId },
    });
    if (!existing) throw new NotFoundException('İşlem bulunamadı');

    if (existing.source !== TransactionSource.MANUAL) {
      throw new BadRequestException(
        'Otomatik oluşturulan işlemler düzenlenemez. Bağlı borç/abonelik kaydından yönetin.',
      );
    }

    const newAmount = dto.amount ?? Number(existing.amount);
    const newType = dto.type ?? existing.type;
    const oldAmount = Number(existing.amount);

    if (newType === TransactionType.INCOME) {
      const account = await this.prisma.account.findFirst({
        where: { id: existing.accountId },
        select: { type: true },
      });
      if (account?.type === AccountType.CREDIT_CARD) {
        throw new BadRequestException(
          'Kredi kartı hesabına gelir kaydedilemez. Kart borcu kapatmak için hesaplar arası transfer kullanın.',
        );
      }
    }

    // Bakiye düzeltmesi: eski işlemi geri al, yeni işlemi uygula
    const transaction = await this.prisma.$transaction(async (tx) => {
      // Eski bakiye etkisini geri al
      await this.balanceService.revert(
        tx,
        existing.accountId,
        existing.type,
        oldAmount,
        existing.transferToAccountId ?? undefined,
      );

      // Yeni bakiye etkisini uygula (TRANSFER güncelleme desteklenmez)
      await this.balanceService.apply(
        tx,
        existing.accountId,
        newType,
        newAmount,
      );

      // Tag'leri güncelle
      if (dto.tagIds !== undefined) {
        await tx.transactionTag.deleteMany({ where: { transactionId: id } });
        if (dto.tagIds.length > 0) {
          await tx.transactionTag.createMany({
            data: dto.tagIds.map((tagId) => ({ transactionId: id, tagId })),
          });
        }
      }

      return tx.transaction.update({
        where: { id },
        data: {
          ...(dto.categoryId !== undefined && { categoryId: dto.categoryId }),
          ...(dto.type !== undefined && { type: dto.type }),
          ...(dto.amount !== undefined && { amount: dto.amount }),
          ...(dto.title !== undefined && { title: dto.title }),
          ...(dto.note !== undefined && { note: dto.note }),
          ...(dto.transactionDate !== undefined && {
            transactionDate: new Date(dto.transactionDate),
          }),
          ...(dto.sharedBudgetId !== undefined && {
            sharedBudgetId: dto.sharedBudgetId,
          }),
        },
        include: {
          category: true,
          account: {
            select: {
              id: true,
              name: true,
              icon: true,
              color: true,
              type: true,
            },
          },
          tags: { include: { tag: true } },
        },
      });
    });

    this.eventEmitter.emit(
      'transaction.updated',
      new TransactionUpdatedEvent(
        id,
        userId,
        existing.categoryId,
        dto.categoryId ?? existing.categoryId,
        existing.type,
        newType,
        oldAmount,
        newAmount,
        transaction.transactionDate,
        existing.sharedBudgetId,
        dto.sharedBudgetId !== undefined
          ? dto.sharedBudgetId
          : existing.sharedBudgetId,
      ),
    );

    return this.format(transaction);
  }

  async remove(userId: string, id: string) {
    const existing = await this.prisma.transaction.findFirst({
      where: { id, userId },
    });
    if (!existing) throw new NotFoundException('İşlem bulunamadı');

    const amount = Number(existing.amount);

    await this.prisma.$transaction(async (tx) => {
      // Bakiyeyi geri al
      await this.balanceService.revert(
        tx,
        existing.accountId,
        existing.type,
        amount,
        existing.transferToAccountId ?? undefined,
      );
      await tx.transaction.delete({ where: { id } });
    });

    this.eventEmitter.emit(
      'transaction.deleted',
      new TransactionDeletedEvent(
        id,
        userId,
        existing.categoryId,
        existing.type,
        amount,
        existing.transactionDate,
        existing.sharedBudgetId,
      ),
    );

    return { message: 'İşlem silindi' };
  }

  private async createRecurringTemplate(
    userId: string,
    dto: CreateTransactionDto,
    startDate: Date,
  ) {
    const nextRunDate = advanceByFrequency(startDate, dto.frequency!);

    await this.prisma.recurringTransaction.create({
      data: {
        userId,
        accountId: dto.accountId,
        categoryId: dto.categoryId ?? null,
        type: dto.type,
        amount: dto.amount,
        title: dto.title,
        note: dto.note ?? null,
        frequency: dto.frequency!,
        startDate,
        endDate: dto.endDate ? new Date(dto.endDate) : null,
        nextRunDate,
      },
    });
  }

  private format(t: any) {
    return {
      ...t,
      amount: Number(t.amount),
      date: t.transactionDate,
      description: t.title,
      tags: t.tags?.map((tt: any) => tt.tag) ?? [],
    };
  }
}
