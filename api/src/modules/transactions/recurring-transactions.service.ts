import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import type { Account, Category, RecurringTransaction } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { BalanceService } from '../../common/services/balance.service';
import { advanceByFrequency } from '../../common/utils/frequency.utils';
import { CreateRecurringTransactionDto } from './dto/create-recurring-transaction.dto';
import { UpdateRecurringTransactionDto } from './dto/update-recurring-transaction.dto';

type RecurringTransactionFull = RecurringTransaction & {
  account: Pick<Account, 'id' | 'name' | 'icon' | 'color'>;
  category: Category | null;
};

@Injectable()
export class RecurringTransactionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly balanceService: BalanceService,
  ) {}

  findAll(userId: string) {
    return this.prisma.recurringTransaction.findMany({
      where: { userId },
      include: {
        account: { select: { id: true, name: true, icon: true, color: true } },
        category: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  findOne(userId: string, id: string) {
    return this.findOwned(userId, id);
  }

  create(
    userId: string,
    dto: CreateRecurringTransactionDto,
  ): Promise<RecurringTransactionFull> {
    const startDate = dto.startDate ? new Date(dto.startDate) : new Date();
    const nextRunDate = advanceByFrequency(startDate, dto.frequency);

    return this.prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      const template = await tx.recurringTransaction.create({
        data: {
          userId,
          accountId: dto.accountId,
          categoryId: dto.categoryId ?? null,
          type: dto.type,
          amount: dto.amount,
          title: dto.title,
          note: dto.note ?? null,
          frequency: dto.frequency,
          startDate,
          endDate: dto.endDate ? new Date(dto.endDate) : null,
          nextRunDate,
        },
        include: {
          account: {
            select: { id: true, name: true, icon: true, color: true },
          },
          category: true,
        },
      });

      // İlk işlemi hemen oluştur (startDate bugün veya geçmişte)
      await tx.transaction.create({
        data: {
          userId,
          accountId: dto.accountId,
          categoryId: dto.categoryId ?? null,
          type: dto.type,
          amount: dto.amount,
          title: dto.title,
          note: dto.note ?? null,
          transactionDate: startDate,
          source: 'RECURRING',
        },
      });

      await this.balanceService.apply(
        tx,
        dto.accountId,
        dto.type,
        Number(dto.amount),
      );

      return template;
    }) as Promise<RecurringTransactionFull>;
  }

  async update(userId: string, id: string, dto: UpdateRecurringTransactionDto) {
    await this.findOwned(userId, id);

    return this.prisma.recurringTransaction.update({
      where: { id },
      data: {
        ...(dto.categoryId !== undefined && { categoryId: dto.categoryId }),
        ...(dto.type !== undefined && { type: dto.type }),
        ...(dto.amount !== undefined && { amount: dto.amount }),
        ...(dto.title !== undefined && { title: dto.title }),
        ...(dto.note !== undefined && { note: dto.note }),
        ...(dto.frequency !== undefined && { frequency: dto.frequency }),
        ...(dto.endDate !== undefined && { endDate: new Date(dto.endDate) }),
        ...(dto.isActive !== undefined && { isActive: dto.isActive }),
      },
      include: {
        account: { select: { id: true, name: true, icon: true, color: true } },
        category: true,
      },
    });
  }

  async remove(userId: string, id: string) {
    await this.findOwned(userId, id);
    await this.prisma.recurringTransaction.delete({ where: { id } });
    return { message: 'Tekrarlayan işlem şablonu silindi' };
  }

  private async findOwned(userId: string, id: string) {
    const record = await this.prisma.recurringTransaction.findFirst({
      where: { id, userId },
      include: {
        account: { select: { id: true, name: true, icon: true, color: true } },
        category: true,
      },
    });
    if (!record) throw new NotFoundException('Tekrarlayan işlem bulunamadı');
    return record;
  }
}
