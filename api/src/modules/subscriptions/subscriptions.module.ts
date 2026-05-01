import { Module } from '@nestjs/common';
import { SubscriptionsController } from './subscriptions.controller';
import { SubscriptionsService } from './subscriptions.service';
import { SubscriptionRenewalJob } from './jobs/subscription-renewal.job';
import { UpcomingRenewalNotifyJob } from './jobs/upcoming-renewal-notify.job';

@Module({
  controllers: [SubscriptionsController],
  providers: [SubscriptionsService, SubscriptionRenewalJob, UpcomingRenewalNotifyJob],
  exports: [SubscriptionsService],
})
export class SubscriptionsModule {}
