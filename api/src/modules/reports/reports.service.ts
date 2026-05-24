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

  /**
   * Kategori bazında harcama trendi: her kategori için bu dönem vs bir önceki
   * eşit uzunluktaki dönemin toplamı ve yüzde değişimi. Frontend `TrendItem`
   * sözleşmesiyle birebir (categoryName / currentAmount / previousAmount /
   * changePercent), en çok harcanan kategori başta olacak şekilde sıralı.
   */
  async getTrends(userId: string, query: QueryReportDto) {
    const { startDate, endDate } = this.resolvePeriod(query);
    const periodMs = endDate.getTime() - startDate.getTime();
    const prevEnd = new Date(startDate.getTime() - 1);
    const prevStart = new Date(prevEnd.getTime() - periodMs);

    const [currentRows, previousRows] = await Promise.all([
      this.groupExpenseByCategory(userId, startDate, endDate, query.accountId),
      this.groupExpenseByCategory(userId, prevStart, prevEnd, query.accountId),
    ]);

    const UNCATEGORIZED = '__uncategorized__';
    const keyOf = (id: string | null) => id ?? UNCATEGORIZED;
    const currentMap = new Map(
      currentRows.map((r) => [keyOf(r.categoryId), r.amount]),
    );
    const previousMap = new Map(
      previousRows.map((r) => [keyOf(r.categoryId), r.amount]),
    );

    const keys = new Set<string>([...currentMap.keys(), ...previousMap.keys()]);
    const categoryIds = [...keys].filter((k) => k !== UNCATEGORIZED);
    const categories = await this.prisma.category.findMany({
      where: { id: { in: categoryIds } },
    });
    const catMap = new Map(categories.map((c) => [c.id, c]));

    const round2 = (n: number) => Math.round(n * 100) / 100;

    const items = [...keys].map((key) => {
      const currentAmount = currentMap.get(key) ?? 0;
      const previousAmount = previousMap.get(key) ?? 0;
      // previous yoksa: yeni harcama → +%100; cari yoksa: tamamen kesilmiş → -%100
      const changePercent =
        previousAmount > 0
          ? Math.round(
              ((currentAmount - previousAmount) / previousAmount) * 100 * 10,
            ) / 10
          : currentAmount > 0
            ? 100
            : 0;
      return {
        categoryId: key === UNCATEGORIZED ? null : key,
        categoryName:
          key === UNCATEGORIZED
            ? 'Kategorisiz'
            : (catMap.get(key)?.name ?? 'Kategorisiz'),
        currentAmount: round2(currentAmount),
        previousAmount: round2(previousAmount),
        changePercent,
      };
    });

    // En çok harcanan kategoriler başta
    items.sort((a, b) => b.currentAmount - a.currentAmount);
    return items;
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

  /** Bir dönemdeki EXPENSE işlemlerini kategoriye göre toplar. */
  private async groupExpenseByCategory(
    userId: string,
    startDate: Date,
    endDate: Date,
    accountId?: string,
  ): Promise<Array<{ categoryId: string | null; amount: number }>> {
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
    });

    return rows.map((r) => ({
      categoryId: r.categoryId,
      amount: Number(r._sum.amount ?? 0),
    }));
  }
}
