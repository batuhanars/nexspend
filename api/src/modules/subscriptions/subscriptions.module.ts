import { Module } from '@nestjs/common';
import { SubscriptionsController } from './subscriptions.controller';
import { SubscriptionsService } from './subscriptions.service';
import { SubscriptionRenewalJob } from './jobs/subscription-renewal.job';
import { UpcomingRenewalNotifyJob } from './jobs/upcoming-renewal-notify.job';
import { BalanceService } from '../../common/services/balance.service';

@Module({
  controllers: [SubscriptionsController],
  providers: [
    SubscriptionsService,
    SubscriptionRenewalJob,
    UpcomingRenewalNotifyJob,
    BalanceService,
  ],
  exports: [SubscriptionsService],
})
export class SubscriptionsModule {}
