import { Injectable, BadRequestException } from '@nestjs/common';
import {
  type Prisma,
  TransactionSource,
  TransactionType,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { QueryReportDto, ReportPeriod } from './dto/query-report.dto';

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  async getExpenseDistribution(userId: string, query: QueryReportDto) {
    const { startDate, endDate } = this.resolvePeriod(query);

    const where: Prisma.TransactionWhereInput = {
      userId,
      type: TransactionType.EXPENSE,
    };
    if (query.accountId) where.accountId = query.accountId;
    where.transactionDate = { gte: startDate, lte: endDate };

    const rows = await this.prisma.transaction.groupBy({
      by: ['categoryId'],
      where,
      _sum: { amount: true },
      orderBy: { _sum: { amount: 'desc' } },
    });

    const total = rows.reduce((s, r) => s + Number(r._sum.amount ?? 0), 0);

    const categoryIds = rows
      .map((r) => r.categoryId)
      .filter(Boolean) as string[];
    const categories = await this.prisma.category.findMany({
      where: { id: { in: categoryIds } },
    });
    const catMap = new Map(categories.map((c) => [c.id, c]));

    return rows.map((r) => {
      const cat = r.categoryId ? catMap.get(r.categoryId) : null;
      const amount = Number(r._sum.amount ?? 0);
      return {
        categoryId: r.categoryId,
        categoryName: cat?.name ?? 'Kategorisiz',
        icon: cat?.icon ?? null,
        color: cat?.color ?? null,
        amount,
        percentage:
          total > 0 ? Math.round((amount / total) * 100 * 10) / 10 : 0,
      };
    });
  }

  async getCashFlow(userId: string, query: QueryReportDto) {
    const { startDate, endDate } = this.resolvePeriod(query);

    const where: Prisma.TransactionWhereInput = { userId };
    if (query.accountId) where.accountId = query.accountId;
    where.transactionDate = { gte: startDate, lte: endDate };

    const transactions = await this.prisma.transaction.findMany({
      where,
      select: { type: true, amount: true, transactionDate: true, source: true },
    });

    // Aylara göre grupla — DEBT_COLLECTION gerçek gelir sayılmaz
    const monthMap = new Map<string, { income: number; expense: number }>();

    for (const t of transactions) {
      const key = `${t.transactionDate.getFullYear()}-${String(t.transactionDate.getMonth() + 1).padStart(2, '0')}`;
      if (!monthMap.has(key)) monthMap.set(key, { income: 0, expense: 0 });
      const entry = monthMap.get(key)!;
      if (
        t.type === TransactionType.INCOME &&
        t.source !== TransactionSource.DEBT_COLLECTION
      ) {
        entry.income += Number(t.amount);
      } else if (t.type === TransactionType.EXPENSE) {
        entry.expense += Number(t.amount);
      }
    }

    return Array.from(monthMap.entries())
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([month, data]) => ({
        month,
        income: Math.round(data.income * 100) / 100,
        expense: Math.round(data.expense * 100) / 100,
        net: Math.round((data.income - data.expense) * 100) / 100,
      }));
  }

  async getTrends(userId: string, query: QueryReportDto) {
    const { startDate, endDate } = this.resolvePeriod(query);
    const periodMs = endDate.getTime() - startDate.getTime();
    const prevEnd = new Date(startDate.getTime() - 1);
    const prevStart = new Date(prevEnd.getTime() - periodMs);

    const [current, previous] = await Promise.all([
      this.getPeriodSummary(userId, startDate, endDate, query.accountId),
      this.getPeriodSummary(userId, prevStart, prevEnd, query.accountId),
    ]);

    const expenseChange =
      previous.expense > 0
        ? Math.round(
            ((current.expense - previous.expense) / previous.expense) * 100,
          )
        : null;
    const incomeChange =
      previous.income > 0
        ? Math.round(
            ((current.income - previous.income) / previous.income) * 100,
          )
        : null;

    // Dönem içi en çok harcama kategorileri
    const topCategories = await this.getTopCategories(
      userId,
      startDate,
      endDate,
      query.accountId,
    );

    return {
      current,
      previous,
      expenseChange,
      incomeChange,
      topCategories,
    };
  }

  async getInflationComparison(userId: string, period?: string) {
    const { year, month } = this.resolvePeriodStr(period);

    const lastMonth = month === 1 ? 12 : month - 1;
    const lastYear = month === 1 ? year - 1 : year;

    const budgets = await this.prisma.budget.findMany({
      where: { userId, isActive: true },
      include: {
        category: { select: { id: true, name: true } },
      },
    });

    const rows: Array<{
      categoryId: string;
      categoryName: string;
      lastPeriodSpent: number;
      currentPeriodSpent: number;
      userChangeRate: number | null;
      inflationRate: number;
      status: 'BELOW' | 'EQUAL' | 'ABOVE';
    }> = [];

    const summary = {
      categoriesBelow: 0,
      categoriesAbove: 0,
      categoriesEqual: 0,
    };

    for (const budget of budgets) {
      const inflationMap = await this.prisma.categoryInflationMap.findUnique({
        where: { categoryId: budget.categoryId },
      });
      if (!inflationMap) continue;

      const inflationRate = await this.prisma.inflationRate.findUnique({
        where: {
          categoryKey_year_month: {
            categoryKey: inflationMap.inflationKey,
            year,
            month,
          },
        },
      });

      const [lastAgg, currentAgg] = await Promise.all([
        this.prisma.transaction.aggregate({
          where: {
            userId,
            categoryId: budget.categoryId,
            type: TransactionType.EXPENSE,
            transactionDate: {
              gte: new Date(lastYear, lastMonth - 1, 1),
              lt: new Date(year, month - 1, 1),
            },
          },
          _sum: { amount: true },
        }),
        this.prisma.transaction.aggregate({
          where: {
            userId,
            categoryId: budget.categoryId,
            type: TransactionType.EXPENSE,
            transactionDate: {
              gte: new Date(year, month - 1, 1),
              lt: new Date(year, month, 1),
            },
          },
          _sum: { amount: true },
        }),
      ]);

      const lastPeriodSpent = Number(lastAgg._sum.amount ?? 0);
      const currentPeriodSpent = Number(currentAgg._sum.amount ?? 0);

      const userChangeRate =
        lastPeriodSpent > 0
          ? Math.round(
              ((currentPeriodSpent - lastPeriodSpent) / lastPeriodSpent) *
                100 *
                100,
            ) / 100
          : null;

      const inflRateValue = Number(inflationRate?.monthlyRate ?? 0);

      let status: 'BELOW' | 'EQUAL' | 'ABOVE' = 'EQUAL';
      if (userChangeRate !== null) {
        if (userChangeRate > inflRateValue + 1) status = 'ABOVE';
        else if (userChangeRate < inflRateValue - 1) status = 'BELOW';
      }

      rows.push({
        categoryId: budget.category.id,
        categoryName: budget.category.name,
        lastPeriodSpent,
        currentPeriodSpent,
        userChangeRate,
        inflationRate: inflRateValue,
        status,
      });

      if (status === 'ABOVE') summary.categoriesAbove++;
      else if (status === 'BELOW') summary.categoriesBelow++;
      else summary.categoriesEqual++;
    }

    return {
      period: `${year}-${String(month).padStart(2, '0')}`,
      rows,
      summary,
    };
  }

  // =============================================
  // Helpers
  // =============================================

  private resolvePeriodStr(periodStr?: string): {
    year: number;
    month: number;
  } {
    if (!periodStr) {
      const now = new Date();
      return { year: now.getFullYear(), month: now.getMonth() + 1 };
    }
    const match = /^(\d{4})-(\d{2})$/.exec(periodStr);
    if (!match) {
      throw new BadRequestException(
        'Geçersiz period formatı. Beklenen format: YYYY-MM',
      );
    }
    const year = parseInt(match[1], 10);
    const month = parseInt(match[2], 10);
    if (month < 1 || month > 12) {
      throw new BadRequestException('Geçersiz ay değeri');
    }
    return { year, month };
  }

  private resolvePeriod(query: QueryReportDto): {
    startDate: Date;
    endDate: Date;
  } {
    const now = new Date();

    if (
      query.period === ReportPeriod.CUSTOM &&
      query.startDate &&
      query.endDate
    ) {
      return {
        startDate: new Date(query.startDate),
        endDate: new Date(query.endDate),
      };
    }

    if (query.period === ReportPeriod.LAST_3_MONTHS) {
      const start = new Date(now);
      start.setMonth(start.getMonth() - 3);
      start.setDate(1);
      start.setHours(0, 0, 0, 0);
      return { startDate: start, endDate: now };
    }

    if (query.period === ReportPeriod.THIS_YEAR) {
      const start = new Date(now.getFullYear(), 0, 1);
      return { startDate: start, endDate: now };
    }

    // THIS_MONTH (default)
    const start = new Date(now.getFullYear(), now.getMonth(), 1);
    return { startDate: start, endDate: now };
  }

  private async getPeriodSummary(
    userId: string,
    startDate: Date,
    endDate: Date,
    accountId?: string,
  ) {
    const where: Prisma.TransactionWhereInput = {
      userId,
      transactionDate: { gte: startDate, lte: endDate },
    };
    if (accountId) where.accountId = accountId;

    const [incomeAgg, expenseAgg] = await Promise.all([
      this.prisma.transaction.aggregate({
        where: {
          ...where,
          type: TransactionType.INCOME,
          source: { not: TransactionSource.DEBT_COLLECTION },
        },
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

  private async getTopCategories(
    userId: string,
    startDate: Date,
    endDate: Date,
    accountId?: string,
    limit = 5,
  ) {
    const where: Prisma.TransactionWhereInput = {
      userId,
      type: TransactionType.EXPENSE,
      transactionDate: { gte: startDate, lte: endDate },
    };
    if (accountId) where.accountId = accountId;

    const rows = await this.prisma.transaction.groupBy({
      by: ['categoryId'],
      where,
      _sum: { amount: true },
      orderBy: { _sum: { amount: 'desc' } },
      take: limit,
    });

    const ids = rows.map((r) => r.categoryId).filter(Boolean) as string[];
    const cats = await this.prisma.category.findMany({
      where: { id: { in: ids } },
    });
    const catMap = new Map(cats.map((c) => [c.id, c]));

    return rows.map((r) => ({
      categoryId: r.categoryId,
      categoryName: r.categoryId
        ? (catMap.get(r.categoryId)?.name ?? 'Kategorisiz')
        : 'Kategorisiz',
      icon: r.categoryId ? (catMap.get(r.categoryId)?.icon ?? null) : null,
      amount: Number(r._sum.amount ?? 0),
    }));
  }
}
