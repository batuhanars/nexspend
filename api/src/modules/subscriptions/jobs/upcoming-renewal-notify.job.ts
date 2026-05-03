import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { SubscriptionsService } from '../subscriptions.service';
import { NotificationsService } from '../../notifications/notifications.service';

@Injectable()
export class UpcomingRenewalNotifyJob {
  private readonly logger = new Logger(UpcomingRenewalNotifyJob.name);

  constructor(
    private readonly subscriptionsService: SubscriptionsService,
    private readonly notifications: NotificationsService,
  ) {}

  @Cron('0 9 * * *') // Her gün 09:00
  async run() {
    const upcoming = await this.subscriptionsService.getUpcomingForNotify();
    if (upcoming.length === 0) return;

    this.logger.log(`${upcoming.length} abonelik yarın yenilenecek`);

    for (const sub of upcoming) {
      this.logger.log(
        `[Bildirim] ${sub.user.fullName} — yarın yenilenecek: ${sub.name}`,
      );
      await this.notifications.sendToUser(
        sub.userId,
        'Abonelik Yenileniyor',
        `${sub.name} aboneliğiniz yarın yenilenecek.`,
      );
    }
  }
}
