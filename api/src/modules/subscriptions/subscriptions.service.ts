/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-argument */
import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  TransactionType,
  TransactionSource,
  SubscriptionPeriod,
  SubscriptionKind,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { BalanceService } from '../../common/services/balance.service';
import { NotificationsService } from '../notifications/notifications.service';
import { advanceByFrequency } from '../../common/utils/frequency.utils';
import { TransactionCreatedEvent } from '../../common/events/transaction.events';
import { CreateSubscriptionDto } from './dto/create-subscription.dto';
import { UpdateSubscriptionDto } from './dto/update-subscription.dto';
import { PaySubscriptionDto } from './dto/pay-subscription.dto';

@Injectable()
export class SubscriptionsService {
  private readonly logger = new Logger(SubscriptionsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly balanceService: BalanceService,
    private readonly eventEmitter: EventEmitter2,
    private readonly notifications: NotificationsService,
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
    const kind = dto.kind ?? SubscriptionKind.SUBSCRIPTION;
    const isBill = kind === SubscriptionKind.BILL;

    // Abonelikte tutar zorunlu; faturada tahmini tutar opsiyonel (gerçek tutar ödeme anında girilir)
    if (!isBill && dto.amount == null) {
      throw new BadRequestException('Abonelik için tutar zorunludur');
    }

    // Invariant: abonelik daima otomatik yenilenir, fatura daima manuel.
    // (autoDeduct artık kullanıcı tarafından seçilmez, kind'den türetilir.)
    const autoDeduct = !isBill;

    const subscription = await this.prisma.subscription.create({
      data: {
        userId,
        name: dto.name,
        amount: dto.amount ?? 0,
        kind,
        reminderDaysBefore: dto.reminderDaysBefore ?? 3,
        period: dto.period ?? SubscriptionPeriod.MONTHLY,
        icon: dto.icon ?? null,
        color: dto.color ?? null,
        accountId: dto.accountId,
        categoryId: dto.categoryId ?? null,
        startDate: new Date(dto.startDate),
        nextRenewal: new Date(dto.nextRenewal),
        autoDeduct,
      },
      include: {
        account: { select: { id: true, name: true, icon: true, color: true } },
        category: true,
      },
    });

    // Oluşturmada işlem YARATILMAZ. Otomatik kesintili abonelikler ilk kesintiyi
    // yenileme tarihi geldiğinde processRenewals (cron) ile alır. Böylece mevcut
    // bir abonelik gerçek yenileme tarihiyle takibe alındığında çift kayıt olmaz.
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
          ...(dto.reminderDaysBefore !== undefined && {
            reminderDaysBefore: dto.reminderDaysBefore,
          }),
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
        kind: SubscriptionKind.SUBSCRIPTION,
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

  // Cron job tarafından çağrılır — gün başına bir kez bildirim eşiklerini tarar.
  // SUBSCRIPTION: reminderDaysBefore günü + yenileme günü (otomatik kesinti varsa).
  // BILL: reminderDaysBefore günü + son ödeme günü + gecikme (-1/-3).
  // Ek "gönderildi mi" state'i tutulmaz (statement job deseni).
  async notifyUpcoming(): Promise<number> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const subs = await this.prisma.subscription.findMany({
      where: { isActive: true },
    });

    let sent = 0;

    for (const sub of subs) {
      const due = new Date(sub.nextRenewal);
      due.setHours(0, 0, 0, 0);
      const daysUntilDue = Math.round(
        (due.getTime() - today.getTime()) / 86_400_000,
      );

      let title: string | null = null;
      let body: string | null = null;

      if (sub.kind === SubscriptionKind.BILL) {
        if (daysUntilDue === sub.reminderDaysBefore && daysUntilDue > 0) {
          title = 'Son ödeme yaklaşıyor';
          body = `${sub.name} faturanızın son ödeme tarihine ${daysUntilDue} gün kaldı.`;
        } else if (daysUntilDue === 0) {
          title = 'Son ödeme bugün';
          body = `${sub.name} faturanızın son ödeme günü bugün.`;
        } else if (daysUntilDue === -1 || daysUntilDue === -3) {
          title = 'Ödeme gecikti';
          body = `${sub.name} faturası ${-daysUntilDue} gün gecikti.`;
        }
      } else if (sub.autoDeduct) {
        // Otomatik kesintili abonelik — yenileme tarihi yaklaşınca hatırlat
        if (daysUntilDue === sub.reminderDaysBefore && daysUntilDue > 0) {
          title = 'Abonelik yenileniyor';
          body = `${sub.name} aboneliğiniz ${daysUntilDue} gün sonra yenilenecek.`;
        } else if (daysUntilDue === 0) {
          title = 'Abonelik bugün yenileniyor';
          body = `${sub.name} aboneliğiniz bugün yenilenecek.`;
        }
      }

      if (title && body) {
        await this.notifications.sendToUser(sub.userId, title, body, {
          type:
            sub.kind === SubscriptionKind.BILL
              ? 'subscription_bill'
              : 'subscription_renewal',
          subscriptionId: sub.id,
          accountId: sub.accountId,
        });
        sent++;
      }
    }

    return sent;
  }

  // Fatura ödemesi — kullanıcı gerçek tutarı girer, işlem oluşur, son ödeme tarihi ilerler.
  async markPaid(userId: string, id: string, dto: PaySubscriptionDto) {
    const sub = await this.findOwned(userId, id);
    const paidDate = dto.paidDate ? new Date(dto.paidDate) : new Date();

    await this.createRenewalTransaction(userId, sub, dto.amount, paidDate);

    const nextRenewal = advanceByFrequency(
      new Date(sub.nextRenewal),
      sub.period,
    );

    return this.format(
      await this.prisma.subscription.update({
        where: { id },
        data: {
          nextRenewal,
          // Faturada ödenen gerçek tutar bir sonraki tahmini olarak saklanır
          ...(sub.kind === SubscriptionKind.BILL && { amount: dto.amount }),
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

  private async createRenewalTransaction(
    userId: string,
    sub: any,
    amount: number = Number(sub.amount),
    when: Date = new Date(),
  ) {
    const isBill = sub.kind === SubscriptionKind.BILL;
    const title = isBill ? `${sub.name} — Fatura` : `${sub.name} — Abonelik`;

    const transaction = await this.prisma.$transaction(async (tx) => {
      await this.balanceService.apply(
        tx,
        sub.accountId,
        TransactionType.EXPENSE,
        amount,
      );

      return tx.transaction.create({
        data: {
          userId,
          accountId: sub.accountId,
          categoryId: sub.categoryId ?? null,
          type: TransactionType.EXPENSE,
          source: TransactionSource.SUBSCRIPTION,
          amount,
          title,
          transactionDate: when,
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
        amount,
        when,
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
