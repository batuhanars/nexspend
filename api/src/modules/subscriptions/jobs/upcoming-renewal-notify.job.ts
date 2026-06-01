import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { SubscriptionsService } from '../subscriptions.service';

@Injectable()
export class UpcomingRenewalNotifyJob {
  private readonly logger = new Logger(UpcomingRenewalNotifyJob.name);

  constructor(private readonly subscriptionsService: SubscriptionsService) {}

  /// Her gün 09:00. Abonelik: reminderDaysBefore günü + yenileme günü.
  /// Cron günde bir çalıştığı için her eşik bir kez bildirim üretir;
  /// ek state tutulmaz (statement job deseni).
  @Cron('0 9 * * *')
  async run() {
    try {
      const sent = await this.subscriptionsService.notifyUpcoming();
      if (sent > 0) {
        this.logger.log(`${sent} abonelik bildirimi gönderildi`);
      }
    } catch (err) {
      this.logger.error(
        `Abonelik bildirimi hatası: ${(err as Error).message}`,
        (err as Error).stack,
      );
    }
  }
}
