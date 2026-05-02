import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { AccountType, TransactionType } from '@prisma/client';
import { OnEvent } from '@nestjs/event-emitter';
import { startOfMonth, endOfMonth, subMonths } from 'date-fns';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateAccountDto } from './dto/create-account.dto';
import { UpdateAccountDto } from './dto/update-account.dto';
import { TransactionCreatedEvent } from '../../common/events/transaction.events';

@Injectable()
export class AccountsService {
  private readonly logger = new Logger(AccountsService.name);

  constructor(private readonly prisma: PrismaService) {}

  async findAll(userId: string) {
    const accounts = await this.prisma.account.findMany({
      where: { userId, isArchived: false },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'asc' }],
    });
    return accounts.map((a) => this.format(a));
  }

  async findOne(userId: string, id: string) {
    const account = await this.findOwned(userId, id);
    return this.format(account);
  }

  async create(userId: string, dto: CreateAccountDto) {
    if (dto.isDefault) {
      await this.prisma.account.updateMany({
        where: { userId, isDefault: true },
        data: { isDefault: false },
      });
    }

    const account = await this.prisma.account.create({
      data: {
        userId,
        name: dto.name,
        type: dto.type,
        balance: dto.balance ?? 0,
        currency: dto.currency ?? 'TRY',
        icon: dto.icon ?? null,
        color: dto.color ?? null,
        isDefault: dto.isDefault ?? false,
        creditLimit: dto.creditLimit ?? null,
        statementDay: dto.statementDay ?? null,
        paymentDueDay: dto.paymentDueDay ?? null,
      },
    });

    return this.format(account);
  }

  async update(userId: string, id: string, dto: UpdateAccountDto) {
    await this.findOwned(userId, id);

    if (dto.isDefault) {
      await this.prisma.account.updateMany({
        where: { userId, isDefault: true, NOT: { id } },
        data: { isDefault: false },
      });
    }

    const account = await this.prisma.account.update({
      where: { id },
      data: {
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.type !== undefined && { type: dto.type }),
        ...(dto.balance !== undefined && { balance: dto.balance }),
        ...(dto.currency !== undefined && { currency: dto.currency }),
        ...(dto.icon !== undefined && { icon: dto.icon }),
        ...(dto.color !== undefined && { color: dto.color }),
        ...(dto.isDefault !== undefined && { isDefault: dto.isDefault }),
        ...(dto.creditLimit !== undefined && { creditLimit: dto.creditLimit }),
        ...(dto.statementDay !== undefined && {
          statementDay: dto.statementDay,
        }),
        ...(dto.paymentDueDay !== undefined && {
          paymentDueDay: dto.paymentDueDay,
        }),
      },
    });

    return this.format(account);
  }

  async remove(userId: string, id: string) {
    await this.findOwned(userId, id);

    const txCount = await this.prisma.transaction.count({
      where: { OR: [{ accountId: id }, { transferToAccountId: id }] },
    });

    if (txCount > 0) {
      throw new BadRequestException(
        'İşlem geçmişi olan hesap silinemez. Arşivlemeyi deneyin.',
      );
    }

    await this.prisma.account.delete({ where: { id } });
    return { message: 'Hesap silindi' };
  }

  async getSummary(userId: string) {
    const accounts = await this.prisma.account.findMany({
      where: { userId, isArchived: false },
    });

    let totalAssets = 0;
    let ccDebt = 0;

    for (const acc of accounts) {
      const balance = Number(acc.balance);
      if (acc.type !== AccountType.CREDIT_CARD) {
        totalAssets += balance;
      } else if (balance < 0) {
        ccDebt += Math.abs(balance);
      }
    }

    return {
      totalAssets,
      ccDebt,
      netAssets: totalAssets - ccDebt,
    };
  }

  async archive(userId: string, id: string) {
    await this.findOwned(userId, id);

    const account = await this.prisma.account.update({
      where: { id },
      data: { isArchived: true, isActive: false, isDefault: false },
    });

    return this.format(account);
  }

  async restore(userId: string, id: string) {
    const account = await this.prisma.account.findFirst({
      where: { id, userId },
    });
    if (!account) throw new NotFoundException('Hesap bulunamadı');

    const updated = await this.prisma.account.update({
      where: { id },
      data: { isArchived: false, isActive: true },
    });

    return this.format(updated);
  }

  async setDefault(userId: string, id: string) {
    await this.findOwned(userId, id);

    await this.prisma.$transaction([
      this.prisma.account.updateMany({
        where: { userId, isDefault: true },
        data: { isDefault: false },
      }),
      this.prisma.account.update({
        where: { id },
        data: { isDefault: true },
      }),
    ]);

    return { message: 'Varsayılan hesap güncellendi' };
  }

  async getStatement(userId: string, id: string) {
    const account = await this.findOwned(userId, id);

    if (account.type !== AccountType.CREDIT_CARD) {
      throw new BadRequestException(
        'Bu özellik sadece kredi kartları için geçerlidir',
      );
    }

    const now = new Date();
    const periodStart = startOfMonth(now);
    const periodEnd = endOfMonth(now);

    const transactions = await this.prisma.transaction.findMany({
      where: {
        accountId: id,
        transactionDate: { gte: periodStart, lte: periodEnd },
      },
      include: { category: true },
      orderBy: { transactionDate: 'desc' },
    });

    const totalSpent = transactions
      .filter((t) => t.type === 'EXPENSE')
      .reduce((sum, t) => sum + Number(t.amount), 0);

    const creditLimit = Number(account.creditLimit ?? 0);
    const usedAmount = Math.abs(Number(account.balance));

    return {
      periodStart,
      periodEnd,
      statementDay: account.statementDay,
      paymentDueDay: account.paymentDueDay,
      creditLimit,
      usedAmount,
      availableAmount: creditLimit - usedAmount,
      usagePercent:
        creditLimit > 0 ? Math.round((usedAmount / creditLimit) * 100) : 0,
      totalSpentThisMonth: totalSpent,
      transactions,
    };
  }

  async getAnalytics(userId: string, id: string) {
    await this.findOwned(userId, id);

    const now = new Date();

    const monthlyData = await Promise.all(
      Array.from({ length: 6 }, (_, i) => {
        const date = subMonths(now, 5 - i);
        const start = startOfMonth(date);
        const end = endOfMonth(date);

        return Promise.all([
          this.prisma.transaction.aggregate({
            where: {
              accountId: id,
              type: 'INCOME',
              transactionDate: { gte: start, lte: end },
            },
            _sum: { amount: true },
          }),
          this.prisma.transaction.aggregate({
            where: {
              accountId: id,
              type: 'EXPENSE',
              transactionDate: { gte: start, lte: end },
            },
            _sum: { amount: true },
          }),
        ]).then(([inc, exp]) => ({
          month: date.toISOString().slice(0, 7),
          income: Number(inc._sum.amount ?? 0),
          expense: Number(exp._sum.amount ?? 0),
        }));
      }),
    );

    const categoryStats = await this.prisma.transaction.groupBy({
      by: ['categoryId'],
      where: {
        accountId: id,
        type: 'EXPENSE',
        transactionDate: { gte: startOfMonth(now) },
      },
      _sum: { amount: true },
      orderBy: { _sum: { amount: 'desc' } },
      take: 5,
    });

    const topCategories = await Promise.all(
      categoryStats.map(async (stat) => {
        const category = stat.categoryId
          ? await this.prisma.category.findUnique({
              where: { id: stat.categoryId },
            })
          : null;
        return {
          categoryId: stat.categoryId,
          name: category?.name ?? 'Kategorisiz',
          icon: category?.icon ?? 'category',
          color: category?.color ?? '#9E9E9E',
          amount: Number(stat._sum.amount ?? 0),
        };
      }),
    );

    return { months: monthlyData, topCategories };
  }

  async getTransactions(
    userId: string,
    id: string,
    page: number = 1,
    limit: number = 20,
  ) {
    await this.findOwned(userId, id);

    const skip = (page - 1) * limit;

    const [transactions, total] = await Promise.all([
      this.prisma.transaction.findMany({
        where: { accountId: id },
        include: { category: true },
        orderBy: { transactionDate: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.transaction.count({ where: { accountId: id } }),
    ]);

    return {
      data: transactions,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  // =============================================
  // CC Limit Kontrolü (Event-Driven)
  // =============================================

  @OnEvent('transaction.created')
  async onTransactionCreated(event: TransactionCreatedEvent) {
    if (event.type !== TransactionType.EXPENSE) return;

    const account = await this.prisma.account.findFirst({
      where: { id: event.accountId, type: AccountType.CREDIT_CARD },
      select: { name: true, balance: true, creditLimit: true },
    });

    if (!account || !account.creditLimit) return;

    const limit = Number(account.creditLimit);
    const used = Math.abs(Math.min(Number(account.balance), 0));
    const pct = limit > 0 ? (used / limit) * 100 : 0;

    if (pct >= 100) {
      this.logger.warn(
        `💳 CC Limit AŞILDI [${account.name}] — %${Math.round(pct)} (${used}/${limit} TL)`,
      );
    } else if (pct >= 90) {
      this.logger.warn(
        `💳 CC Limit KRİTİK [${account.name}] — %${Math.round(pct)} (${used}/${limit} TL)`,
      );
    } else if (pct >= 80) {
      this.logger.log(
        `💳 CC Limit UYARISI [${account.name}] — %${Math.round(pct)} (${used}/${limit} TL)`,
      );
    }
  }

  private async findOwned(userId: string, id: string) {
    const account = await this.prisma.account.findFirst({
      where: { id, userId },
    });
    if (!account) throw new NotFoundException('Hesap bulunamadı');
    return account;
  }

  private format(account: {
    balance: unknown;
    creditLimit: unknown;
    [key: string]: unknown;
  }) {
    return {
      ...account,
      balance: Number(account.balance),
      creditLimit:
        account.creditLimit !== null ? Number(account.creditLimit) : null,
    };
  }
}
