import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { AccountType } from '@prisma/client';
import { PrismaService } from '../../../prisma/prisma.service';
import { NotificationsService } from '../../notifications/notifications.service';

@Injectable()
export class CreditCardStatementJob {
  private readonly logger = new Logger(CreditCardStatementJob.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

  @Cron('0 8 * * *') // Her gün 08:00
  async run() {
    const today = new Date().getDate(); // 1-31

    // Bugün ekstre kesim günü olan kredi kartlarını bul
    const cards = await this.prisma.account.findMany({
      where: {
        type: AccountType.CREDIT_CARD,
        isArchived: false,
        statementDay: today,
        creditLimit: { not: null },
      },
      include: {
        user: { select: { email: true, fullName: true } },
      },
    });

    if (cards.length === 0) return;

    this.logger.log(
      `${cards.length} kredi kartı için ekstre bildirimi hazırlanıyor`,
    );

    for (const card of cards) {
      const limit = Number(card.creditLimit!);
      const balance = Number(card.balance);
      const used = Math.abs(Math.min(balance, 0));
      const available = limit - used;
      const pct = limit > 0 ? Math.round((used / limit) * 100) : 0;

      this.logger.log(
        `📋 Ekstre Kesim Günü [${card.name}] — ` +
          `Kullanılan: ₺${used.toFixed(2)} / Limit: ₺${limit.toFixed(2)} ` +
          `(${pct}%) — Kullanılabilir: ₺${available.toFixed(2)} ` +
          `[${card.user.email}]`,
      );

      await this.notifications.sendToUser(
        card.userId,
        'Ekstre Kesim Günü',
        `${card.name}: ₺${used.toFixed(2)} kullanıldı, ₺${available.toFixed(2)} kullanılabilir.`,
      );

      // Son ödeme günü bildirimi
      if (card.paymentDueDay) {
        const paymentDate = new Date();
        paymentDate.setDate(card.paymentDueDay);
        if (paymentDate.getDate() < today) {
          paymentDate.setMonth(paymentDate.getMonth() + 1);
        }
        this.logger.log(
          `📅 Son Ödeme Tarihi: ${paymentDate.toLocaleDateString('tr-TR')} [${card.name}]`,
        );
        await this.notifications.sendToUser(
          card.userId,
          'Son Ödeme Tarihi Hatırlatması',
          `${card.name} son ödeme tarihi: ${paymentDate.toLocaleDateString('tr-TR')}.`,
        );
      }
    }
  }
}
