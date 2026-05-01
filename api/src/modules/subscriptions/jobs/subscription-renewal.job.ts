import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { SubscriptionsService } from '../subscriptions.service';

@Injectable()
export class SubscriptionRenewalJob {
  private readonly logger = new Logger(SubscriptionRenewalJob.name);

  constructor(private readonly subscriptionsService: SubscriptionsService) {}

  @Cron('15 0 * * *') // Her gün 00:15
  async run() {
    this.logger.log('Abonelik yenileme işlemi başladı');
    await this.subscriptionsService.processRenewals();
  }
}
