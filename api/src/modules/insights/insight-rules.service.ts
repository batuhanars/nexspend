import { Injectable, Logger } from '@nestjs/common';
import {
  BudgetPeriod,
  DebtStatus,
  DebtType,
  TransactionSource,
  TransactionType,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { InsightRuleId } from './insight.constants';

export interface InsightRuleResult {
  ruleId: InsightRuleId;
  title: string;
  message: string;
  category?: string;
}

@Injectable()
export class InsightRulesService {
  private readonly logger = new Logger(InsightRulesService.name);

  constructor(private readonly prisma: PrismaService) {}

  async runAll(userId: string, period: string): Promise<InsightRuleResult[]> {
    const rules: (() => Promise<InsightRuleResult | null>)[] = [
      () => this.checkSpendingSpike(userId, period),
      () => this.checkUnusedSubscription(userId),
      () => this.checkCategoryOverrun(userId, period),
      () => this.checkRecurringDrift(userId, period),
      () => this.checkDebtAging(userId),
      () => this.checkInflationGap(userId, period),
      () => this.checkSavingStreak(userId, period),
    ];

    const results: InsightRuleResult[] = [];
    for (const rule of rules) {
      try {
        const result = await rule();
        if (result) results.push(result);
      } catch (err) {
        this.logger.warn(
          `Kural başarısız, atlanıyor: ${(err as Error).message}`,
        );
      }
    }
    return results;
  }

  async checkSpendingSpike(
    userId: string,
    period: string,
  ): Promise<InsightRuleResult | null> {
    const { start, end } = this.periodToDateRange(period);
    const prev3Start = new Date(start.getFullYear(), start.getMonth() - 3, 1);
    const prev3End = new Date(
      start.getFullYear(),
      start.getMonth(),
      0,
      23,
      59,
      59,
      999,
    );

    const [currentSpending, prevSpending] = await Promise.all([
      this.prisma.transaction.groupBy({
        by: ['categoryId'],
        where: {
          userId,
          type: TransactionType.EXPENSE,
          transactionDate: { gte: start, lte: end },
          categoryId: { not: null },
        },
        _sum: { amount: true },
      }),
      this.prisma.transaction.groupBy({
        by: ['categoryId'],
        where: {
          userId,
          type: TransactionType.EXPENSE,
          transactionDate: { gte: prev3Start, lte: prev3End },
          categoryId: { not: null },
        },
        _sum: { amount: true },
      }),
    ]);

    if (currentSpending.length === 0) return null;

    const prevMap = new Map<string, number>();
    for (const p of prevSpending) {
      if (p.categoryId)
        prevMap.set(p.categoryId, Number(p._sum.amount ?? 0) / 3);
    }

    let best: {
      categoryId: string;
      pct: number;
      current: number;
      avg: number;
    } | null = null;

    for (const c of currentSpending) {
      if (!c.categoryId) continue;
      const current = Number(c._sum.amount ?? 0);
      const avg = prevMap.get(c.categoryId) ?? 0;
      if (avg === 0) continue;
      const pct = (current - avg) / avg;
      if (pct >= 0.3 && (!best || pct > best.pct)) {
        best = { categoryId: c.categoryId, pct, current, avg };
      }
    }

    if (!best) return null;

    const category = await this.prisma.category.findUnique({
      where: { id: best.categoryId },
      select: { name: true },
    });
    const catName = category?.name ?? 'Bilinmeyen';
    const pctStr = Math.round(best.pct * 100);
    const diff = Math.round(best.current - best.avg);

    return {
      ruleId: 'spending_spike',
      title: `${catName} harcaman bu ay %${pctStr} arttı`,
      message: `Geçen 3 ayın ortalaması ₺${this.fmt(best.avg)}, bu ay ₺${this.fmt(best.current)}. Fark: +₺${this.fmt(diff)}.`,
      category: catName,
    };
  }

  async checkUnusedSubscription(
    userId: string,
  ): Promise<InsightRuleResult | null> {
    const subscriptions = await this.prisma.subscription.findMany({
      where: { userId, isActive: true, categoryId: { not: null } },
      include: { category: { select: { name: true } } },
      orderBy: { amount: 'desc' },
    });

    if (subscriptions.length === 0) return null;

    const sixtyDaysAgo = new Date();
    sixtyDaysAgo.setDate(sixtyDaysAgo.getDate() - 60);

    for (const sub of subscriptions) {
      if (!sub.categoryId) continue;

      const txCount = await this.prisma.transaction.count({
        where: {
          userId,
          categoryId: sub.categoryId,
          type: TransactionType.EXPENSE,
          transactionDate: { gte: sixtyDaysAgo },
        },
      });

      if (txCount === 0) {
        const yearlyAmount = this.toYearly(Number(sub.amount), sub.period);
        return {
          ruleId: 'unused_subscription',
          title: `${sub.name} son 60 günde kullanılmadı`,
          message: `${sub.name}'ı 2 aydır kullanmıyorsun 👀 Yıllık tasarruf: ₺${this.fmt(yearlyAmount)}`,
        };
      }
    }

    return null;
  }

  async checkCategoryOverrun(
    userId: string,
    period: string,
  ): Promise<InsightRuleResult | null> {
    const { year, month } = this.parsePeriod(period);
    const periodStart = new Date(year, month - 1, 1);
    const day15End = new Date(year, month - 1, 15, 23, 59, 59, 999);

    const budgets = await this.prisma.budget.findMany({
      where: { userId, isActive: true, period: BudgetPeriod.MONTHLY },
      include: { category: { select: { name: true } } },
    });

    if (budgets.length === 0) return null;

    let worst: {
      categoryName: string;
      budgetName: string;
      amount: number;
      spentBy15: number;
      pct: number;
    } | null = null;

    for (const budget of budgets) {
      const spent = await this.prisma.transaction.aggregate({
        where: {
          userId,
          categoryId: budget.categoryId,
          type: TransactionType.EXPENSE,
          transactionDate: { gte: periodStart, lte: day15End },
        },
        _sum: { amount: true },
      });

      const spentBy15 = Number(spent._sum.amount ?? 0);
      const budgetAmount = Number(budget.amount);
      if (budgetAmount === 0) continue;
      const pct = spentBy15 / budgetAmount;

      if (pct >= 0.7 && (!worst || pct > worst.pct)) {
        worst = {
          categoryName: budget.category.name,
          budgetName: budget.name,
          amount: budgetAmount,
          spentBy15,
          pct,
        };
      }
    }

    if (!worst) return null;

    const remaining = Math.max(0, worst.amount - worst.spentBy15);
    const projected = Math.round(worst.spentBy15 * 2);

    return {
      ruleId: 'category_overrun',
      title: `${worst.categoryName} bütçen bu hızla aşılacak`,
      message: `${worst.categoryName} bütçen bu hızla ₺${this.fmt(projected)} ile kapanır. Kalan bütçe: ₺${this.fmt(remaining)}`,
      category: worst.categoryName,
    };
  }

  async checkRecurringDrift(
    userId: string,
    period: string,
  ): Promise<InsightRuleResult | null> {
    const { year, month } = this.parsePeriod(period);
    const threeMonthsAgo = new Date(year, month - 4, 1);
    const periodEnd = new Date(year, month, 0, 23, 59, 59, 999);

    const transactions = await this.prisma.transaction.findMany({
      where: {
        userId,
        source: TransactionSource.RECURRING,
        transactionDate: { gte: threeMonthsAgo, lte: periodEnd },
      },
      select: { title: true, amount: true, transactionDate: true },
      orderBy: { transactionDate: 'asc' },
    });

    if (transactions.length === 0) return null;

    const groups = new Map<string, { amount: number; monthKey: number }[]>();
    for (const tx of transactions) {
      const monthKey =
        tx.transactionDate.getFullYear() * 12 + tx.transactionDate.getMonth();
      if (!groups.has(tx.title)) groups.set(tx.title, []);
      groups.get(tx.title)!.push({ amount: Number(tx.amount), monthKey });
    }

    let worst: {
      title: string;
      firstAmount: number;
      lastAmount: number;
      pct: number;
    } | null = null;

    for (const [title, entries] of groups) {
      const uniqueMonths = new Set(entries.map((e) => e.monthKey));
      if (uniqueMonths.size < 2) continue;

      const firstAmount = entries[0].amount;
      const lastAmount = entries[entries.length - 1].amount;
      if (firstAmount === 0) continue;

      const pct = Math.abs(lastAmount - firstAmount) / firstAmount;
      if (pct >= 0.2 && (!worst || pct > worst.pct)) {
        worst = { title, firstAmount, lastAmount, pct };
      }
    }

    if (!worst) return null;

    const direction =
      worst.lastAmount > worst.firstAmount ? 'artıyor' : 'azalıyor';

    return {
      ruleId: 'recurring_drift',
      title: `${worst.title} tutarı değişiyor`,
      message: `${worst.title} 3 aydır ${direction}: ₺${this.fmt(worst.firstAmount)} → ₺${this.fmt(worst.lastAmount)}`,
    };
  }

  async checkDebtAging(userId: string): Promise<InsightRuleResult | null> {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const debt = await this.prisma.debt.findFirst({
      where: {
        userId,
        type: DebtType.LENT,
        status: { not: DebtStatus.PAID },
        createdAt: { lte: thirtyDaysAgo },
      },
      orderBy: { createdAt: 'asc' },
    });

    if (!debt) return null;

    const remaining = Number(debt.totalAmount) - Number(debt.paidAmount);
    const daysAgo = Math.floor(
      (Date.now() - debt.createdAt.getTime()) / (1000 * 60 * 60 * 24),
    );

    return {
      ruleId: 'debt_aging',
      title: `${debt.personName}'e verilen ₺${this.fmt(remaining)} tahsil edilmedi`,
      message: `${debt.personName}'e verilen ₺${this.fmt(remaining)} ${daysAgo} gündür tahsil edilmedi`,
    };
  }

  async checkInflationGap(
    userId: string,
    period: string,
  ): Promise<InsightRuleResult | null> {
    const inflationCount = await this.prisma.inflationRate.count();
    if (inflationCount === 0) return null;

    const { year, month } = this.parsePeriod(period);
    const { start: currStart, end: currEnd } = this.periodToDateRange(period);
    const prevPeriodStr = this.prevPeriod(period, 1);
    const { start: prevStart, end: prevEnd } =
      this.periodToDateRange(prevPeriodStr);

    const [currentSpending, prevSpending] = await Promise.all([
      this.prisma.transaction.groupBy({
        by: ['categoryId'],
        where: {
          userId,
          type: TransactionType.EXPENSE,
          transactionDate: { gte: currStart, lte: currEnd },
          categoryId: { not: null },
        },
        _sum: { amount: true },
      }),
      this.prisma.transaction.groupBy({
        by: ['categoryId'],
        where: {
          userId,
          type: TransactionType.EXPENSE,
          transactionDate: { gte: prevStart, lte: prevEnd },
          categoryId: { not: null },
        },
        _sum: { amount: true },
      }),
    ]);

    if (currentSpending.length === 0) return null;

    const prevMap = new Map<string, number>();
    for (const p of prevSpending) {
      if (p.categoryId) prevMap.set(p.categoryId, Number(p._sum.amount ?? 0));
    }

    let worst: {
      categoryName: string;
      excessPct: number;
      excessAmt: number;
    } | null = null;

    for (const curr of currentSpending) {
      if (!curr.categoryId) continue;
      const currentAmt = Number(curr._sum.amount ?? 0);
      const prevAmt = prevMap.get(curr.categoryId) ?? 0;
      if (prevAmt === 0) continue;

      const spendingChangePct = ((currentAmt - prevAmt) / prevAmt) * 100;

      const inflationMap = await this.prisma.categoryInflationMap.findUnique({
        where: { categoryId: curr.categoryId },
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
      if (!inflationRate) continue;

      const monthlyInflation = Number(inflationRate.monthlyRate);
      const excessPct = spendingChangePct - monthlyInflation;

      if (excessPct > 5) {
        const excessAmt = Math.round(
          currentAmt - prevAmt * (1 + monthlyInflation / 100),
        );
        if (!worst || excessAmt > worst.excessAmt) {
          const category = await this.prisma.category.findUnique({
            where: { id: curr.categoryId },
            select: { name: true },
          });
          worst = {
            categoryName: category?.name ?? 'Bilinmeyen',
            excessPct,
            excessAmt,
          };
        }
      }
    }

    if (!worst) return null;

    return {
      ruleId: 'inflation_gap',
      title: `${worst.categoryName} harcaman enflasyonun üstünde`,
      message: `${worst.categoryName} harcaman enflasyonun %${worst.excessPct.toFixed(1)} üstünde (+₺${this.fmt(worst.excessAmt)})`,
      category: worst.categoryName,
    };
  }

  async checkSavingStreak(
    userId: string,
    period: string,
  ): Promise<InsightRuleResult | null> {
    const months = [
      this.prevPeriod(period, 2),
      this.prevPeriod(period, 1),
      period,
    ];

    let totalNetFlow = 0;

    for (const m of months) {
      const { start, end } = this.periodToDateRange(m);

      const [income, expense] = await Promise.all([
        this.prisma.transaction.aggregate({
          where: {
            userId,
            type: TransactionType.INCOME,
            source: { not: TransactionSource.DEBT_COLLECTION },
            transactionDate: { gte: start, lte: end },
          },
          _sum: { amount: true },
        }),
        this.prisma.transaction.aggregate({
          where: {
            userId,
            type: TransactionType.EXPENSE,
            transactionDate: { gte: start, lte: end },
          },
          _sum: { amount: true },
        }),
      ]);

      const netFlow =
        Number(income._sum.amount ?? 0) - Number(expense._sum.amount ?? 0);

      if (netFlow <= 0) return null;
      totalNetFlow += netFlow;
    }

    const avgNetFlow = Math.round(totalNetFlow / 3);

    return {
      ruleId: 'saving_streak',
      title: '3 ay üst üste tasarruf ettin!',
      message: `Tebrikler! 3 ay üst üste tasarruf ettin 🎉 Ortalama: +₺${this.fmt(avgNetFlow)}/ay`,
    };
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  private parsePeriod(period: string): { year: number; month: number } {
    const [y, m] = period.split('-').map(Number);
    return { year: y, month: m };
  }

  private periodToDateRange(period: string): { start: Date; end: Date } {
    const { year, month } = this.parsePeriod(period);
    const start = new Date(year, month - 1, 1);
    const end = new Date(year, month, 0, 23, 59, 59, 999);
    return { start, end };
  }

  private prevPeriod(period: string, monthsBack: number): string {
    const { year, month } = this.parsePeriod(period);
    const d = new Date(year, month - 1 - monthsBack, 1);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
  }

  private toYearly(amount: number, period: string): number {
    if (period === 'YEARLY') return amount;
    if (period === 'WEEKLY') return amount * 52;
    return amount * 12; // MONTHLY
  }

  private fmt(amount: number): string {
    return Math.round(amount)
      .toString()
      .replace(/\B(?=(\d{3})+(?!\d))/g, '.');
  }
}
