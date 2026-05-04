import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateRecurringTransactionDto } from './dto/create-recurring-transaction.dto';
import { UpdateRecurringTransactionDto } from './dto/update-recurring-transaction.dto';

@Injectable()
export class RecurringTransactionsService {
  constructor(private readonly prisma: PrismaService) {}

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

  async create(userId: string, dto: CreateRecurringTransactionDto) {
    const startDate = dto.startDate ? new Date(dto.startDate) : new Date();
    const nextRunDate = this.calcNextRunDate(startDate, dto.frequency);

    return this.prisma.$transaction(async (tx) => {
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
          account: { select: { id: true, name: true, icon: true, color: true } },
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

      if (dto.type === 'INCOME') {
        await tx.account.update({
          where: { id: dto.accountId },
          data: { balance: { increment: Number(dto.amount) } },
        });
      } else if (dto.type === 'EXPENSE') {
        await tx.account.update({
          where: { id: dto.accountId },
          data: { balance: { decrement: Number(dto.amount) } },
        });
      }

      return template;
    });
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

  private calcNextRunDate(from: Date, frequency: string): Date {
    const d = new Date(from);
    switch (frequency) {
      case 'DAILY':
        d.setDate(d.getDate() + 1);
        break;
      case 'WEEKLY':
        d.setDate(d.getDate() + 7);
        break;
      case 'MONTHLY':
        d.setMonth(d.getMonth() + 1);
        break;
      case 'YEARLY':
        d.setFullYear(d.getFullYear() + 1);
        break;
    }
    return d;
  }
}
