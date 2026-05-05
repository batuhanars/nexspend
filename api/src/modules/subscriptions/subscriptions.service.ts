/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-argument */
import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  TransactionType,
  TransactionSource,
  SubscriptionPeriod,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { BalanceService } from '../../common/services/balance.service';
import { advanceByFrequency } from '../../common/utils/frequency.utils';
import { TransactionCreatedEvent } from '../../common/events/transaction.events';
import { CreateSubscriptionDto } from './dto/create-subscription.dto';
import { UpdateSubscriptionDto } from './dto/update-subscription.dto';

@Injectable()
export class SubscriptionsService {
  private readonly logger = new Logger(SubscriptionsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly balanceService: BalanceService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async findAll(userId: string) {
    const subs = await this.prisma.subscription.findMany({
      where: { userId },
      include: {
        account: { select: { id: true, name: true, icon: true, color: true } },
        category: true,
      },
      orderBy: { nextRenewal: 'asc' },
    });
    return subs.map((s) => this.format(s));
  }

  async getSummary(userId: string) {
    const active = await this.prisma.subscription.findMany({
      where: { userId, isActive: true },
    });

    const monthly = active.reduce((sum, s) => {
      const amount = Number(s.amount);
      if (s.period === SubscriptionPeriod.WEEKLY) return sum + amount * 4.33;
      if (s.period === SubscriptionPeriod.YEARLY) return sum + amount / 12;
      return sum + amount;
    }, 0);

    return {
      activeCount: active.length,
      monthlyTotal: Math.round(monthly * 100) / 100,
      yearlyTotal: Math.round(monthly * 12 * 100) / 100,
    };
  }

  async getUpcoming(userId: string, days = 7) {
    const from = new Date();
    from.setHours(0, 0, 0, 0);
    const to = new Date(from);
    to.setDate(to.getDate() + days);

    const subs = await this.prisma.subscription.findMany({
      where: {
        userId,
        isActive: true,
        nextRenewal: { gte: from, lte: to },
      },
      include: {
        account: { select: { id: true, name: true, icon: true, color: true } },
        category: true,
      },
      orderBy: { nextRenewal: 'asc' },
    });
    return subs.map((s) => this.format(s));
  }

  async findOne(userId: string, id: string) {
    return this.format(await this.findOwned(userId, id));
  }

  async create(userId: string, dto: CreateSubscriptionDto) {
    const subscription = await this.prisma.subscription.create({
      data: {
        userId,
        name: dto.name,
        amount: dto.amount,
        period: dto.period ?? SubscriptionPeriod.MONTHLY,
        icon: dto.icon ?? null,
        color: dto.color ?? null,
        accountId: dto.accountId,
        categoryId: dto.categoryId ?? null,
        startDate: new Date(dto.startDate),
        nextRenewal: new Date(dto.nextRenewal),
        autoDeduct: dto.autoDeduct ?? true,
      },
      include: {
        account: { select: { id: true, name: true, icon: true, color: true } },
        category: true,
      },
    });

    // İlk satın almada otomatik işlem oluştur
    if (subscription.autoDeduct) {
      await this.createRenewalTransaction(userId, subscription);
    }

    return this.format(subscription);
  }

  async update(userId: string, id: string, dto: UpdateSubscriptionDto) {
    await this.findOwned(userId, id);

    return this.format(
      await this.prisma.subscription.update({
        where: { id },
        data: {
          ...(dto.name !== undefined && { name: dto.name }),
          ...(dto.amount !== undefined && { amount: dto.amount }),
          ...(dto.period !== undefined && { period: dto.period }),
          ...(dto.icon !== undefined && { icon: dto.icon }),
          ...(dto.color !== undefined && { color: dto.color }),
          ...(dto.accountId !== undefined && { accountId: dto.accountId }),
          ...(dto.categoryId !== undefined && { categoryId: dto.categoryId }),
          ...(dto.nextRenewal !== undefined && {
            nextRenewal: new Date(dto.nextRenewal),
          }),
          ...(dto.autoDeduct !== undefined && { autoDeduct: dto.autoDeduct }),
        },
        include: {
          account: {
            select: { id: true, name: true, icon: true, color: true },
          },
          category: true,
        },
      }),
    );
  }

  async remove(userId: string, id: string) {
    await this.findOwned(userId, id);
    await this.prisma.subscription.delete({ where: { id } });
    return { message: 'Abonelik silindi' };
  }

  async toggle(userId: string, id: string) {
    const sub = await this.findOwned(userId, id);
    return this.format(
      await this.prisma.subscription.update({
        where: { id },
        data: { isActive: !sub.isActive },
        include: {
          account: {
            select: { id: true, name: true, icon: true, color: true },
          },
          category: true,
        },
      }),
    );
  }

  // Cron job tarafından çağrılır
  async processRenewals() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const due = await this.prisma.subscription.findMany({
      where: {
        isActive: true,
        autoDeduct: true,
        nextRenewal: { lt: tomorrow },
      },
      include: {
        account: { select: { id: true, name: true, icon: true, color: true } },
        category: true,
      },
    });

    this.logger.log(`${due.length} abonelik yenilenecek`);

    for (const sub of due) {
      try {
        await this.processOneRenewal(sub);
      } catch (err) {
        this.logger.error(`Abonelik ${sub.id} yenilenemedi: ${err}`);
      }
    }
  }

  async getUpcomingForNotify() {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);
    const dayAfter = new Date(tomorrow);
    dayAfter.setDate(dayAfter.getDate() + 1);

    return this.prisma.subscription.findMany({
      where: { isActive: true, nextRenewal: { gte: tomorrow, lt: dayAfter } },
      include: { user: { select: { fullName: true, email: true } } },
    });
  }

  private async processOneRenewal(sub: any) {
    const nextRenewal = advanceByFrequency(
      new Date(sub.nextRenewal),
      sub.period,
    );

    await this.createRenewalTransaction(sub.userId, sub);

    await this.prisma.subscription.update({
      where: { id: sub.id },
      data: { nextRenewal },
    });
  }

  private async createRenewalTransaction(userId: string, sub: any) {
    const now = new Date();

    const transaction = await this.prisma.$transaction(async (tx) => {
      await this.balanceService.apply(
        tx,
        sub.accountId,
        TransactionType.EXPENSE,
        Number(sub.amount),
      );

      return tx.transaction.create({
        data: {
          userId,
          accountId: sub.accountId,
          categoryId: sub.categoryId ?? null,
          type: TransactionType.EXPENSE,
          source: TransactionSource.SUBSCRIPTION,
          amount: sub.amount,
          title: `${sub.name} — Abonelik`,
          transactionDate: now,
          relatedSubId: sub.id,
        },
      });
    });

    this.eventEmitter.emit(
      'transaction.created',
      new TransactionCreatedEvent(
        transaction.id,
        userId,
        sub.accountId,
        sub.categoryId ?? null,
        TransactionType.EXPENSE,
        TransactionSource.SUBSCRIPTION,
        Number(sub.amount),
        now,
      ),
    );
  }

  private async findOwned(userId: string, id: string) {
    const sub = await this.prisma.subscription.findFirst({
      where: { id, userId },
    });
    if (!sub) throw new NotFoundException('Abonelik bulunamadı');
    return sub;
  }

  private format(s: any) {
    return { ...s, amount: Number(s.amount) };
  }
}
