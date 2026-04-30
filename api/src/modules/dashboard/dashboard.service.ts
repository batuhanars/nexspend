import { Injectable } from '@nestjs/common';
import { AccountType } from '@prisma/client';
import { startOfMonth, endOfMonth, subMonths } from 'date-fns';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class DashboardService {
  constructor(private readonly prisma: PrismaService) {}

  async getDashboard(userId: string) {
    const [user, accounts, recentTransactions, monthlySummary] =
      await Promise.all([
        this.prisma.user.findUnique({
          where: { id: userId },
          select: { fullName: true },
        }),
        this.getAccounts(userId),
        this.getRecentTransactions(userId),
        this.getMonthlySummary(userId),
      ]);

    const { totalAssets, ccDebt, netAssets } = this.calcSummary(accounts);

    const lastMonthNetAssets = totalAssets - ccDebt - monthlySummary.change;
    const monthlyChangePercent =
      lastMonthNetAssets !== 0
        ? (monthlySummary.change / Math.abs(lastMonthNetAssets)) * 100
        : 0;

    return {
      totalAssets,
      creditCardDebt: ccDebt,
      netAssets,
      monthlyIncome: monthlySummary.income,
      monthlyExpense: monthlySummary.expense,
      monthlyChange: monthlySummary.change,
      monthlyChangePercent: Math.round(monthlyChangePercent * 10) / 10,
      userFirstName: user?.fullName?.split(' ')[0] ?? null,
      accounts,
      recentTransactions,
    };
  }

  private async getAccounts(userId: string) {
    const accounts = await this.prisma.account.findMany({
      where: { userId, isArchived: false },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'asc' }],
    });

    return accounts.map((a) => ({
      ...a,
      balance: Number(a.balance),
      creditLimit: a.creditLimit !== null ? Number(a.creditLimit) : null,
    }));
  }

  private async getRecentTransactions(userId: string) {
    const transactions = await this.prisma.transaction.findMany({
      where: { userId },
      include: { category: true, account: true },
      orderBy: { transactionDate: 'desc' },
      take: 5,
    });

    return transactions.map((t) => ({
      ...t,
      amount: Number(t.amount),
      date: t.transactionDate,
      description: t.title,
    }));
  }

  private async getMonthlySummary(userId: string) {
    const now = new Date();
    const thisMonthStart = startOfMonth(now);
    const thisMonthEnd = endOfMonth(now);
    const lastMonthStart = startOfMonth(subMonths(now, 1));
    const lastMonthEnd = endOfMonth(subMonths(now, 1));

    const [incomeAgg, expenseAgg, lastMonthIncomeAgg, lastMonthExpenseAgg] =
      await Promise.all([
        this.prisma.transaction.aggregate({
          where: {
            userId,
            type: 'INCOME',
            source: { not: 'DEBT_COLLECTION' },
            transactionDate: { gte: thisMonthStart, lte: thisMonthEnd },
          },
          _sum: { amount: true },
        }),
        this.prisma.transaction.aggregate({
          where: {
            userId,
            type: 'EXPENSE',
            transactionDate: { gte: thisMonthStart, lte: thisMonthEnd },
          },
          _sum: { amount: true },
        }),
        this.prisma.transaction.aggregate({
          where: {
            userId,
            type: 'INCOME',
            source: { not: 'DEBT_COLLECTION' },
            transactionDate: { gte: lastMonthStart, lte: lastMonthEnd },
          },
          _sum: { amount: true },
        }),
        this.prisma.transaction.aggregate({
          where: {
            userId,
            type: 'EXPENSE',
            transactionDate: { gte: lastMonthStart, lte: lastMonthEnd },
          },
          _sum: { amount: true },
        }),
      ]);

    const income = Number(incomeAgg._sum.amount ?? 0);
    const expense = Number(expenseAgg._sum.amount ?? 0);
    const lastMonthNet =
      Number(lastMonthIncomeAgg._sum.amount ?? 0) -
      Number(lastMonthExpenseAgg._sum.amount ?? 0);

    return {
      income,
      expense,
      change: income - expense - lastMonthNet,
    };
  }

  private calcSummary(accounts: any[]) {
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

    return { totalAssets, ccDebt, netAssets: totalAssets - ccDebt };
  }
}
