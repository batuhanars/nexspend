import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { InsightService } from '../insight.service';
import { NotificationsService } from '../../../modules/notifications/notifications.service';
import { PrismaService } from '../../../prisma/prisma.service';

@Injectable()
export class MonthlyInsightJob {
  private readonly logger = new Logger(MonthlyInsightJob.name);

  constructor(
    private readonly insightService: InsightService,
    private readonly notifications: NotificationsService,
    private readonly prisma: PrismaService,
  ) {}

  @Cron('0 8 1 * *')
  async run(): Promise<void> {
    const now = new Date();
    const prev = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const period = `${prev.getFullYear()}-${String(prev.getMonth() + 1).padStart(2, '0')}`;

    this.logger.log(`Aylık insight üretimi başladı (${period})`);
    await this.insightService.generateForAllUsers(period);

    const users = await this.prisma.user.findMany({
      select: { id: true },
      where: { notificationsEnabled: true },
    });

    for (const user of users) {
      try {
        await this.notifications.sendToUser(
          user.id,
          'Aylık Finansal Rapor',
          'Aylık finansal raporun hazır! 📊',
          { type: 'MONTHLY_REPORT' },
        );
      } catch (err) {
        this.logger.warn(
          `Bildirim gönderilemedi [${user.id}]: ${(err as Error).message}`,
        );
      }
    }

    this.logger.log(`Aylık insight üretimi tamamlandı (${period})`);
  }
}
