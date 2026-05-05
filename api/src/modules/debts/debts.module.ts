import { Module } from '@nestjs/common';
import { DebtsController } from './debts.controller';
import { DebtsService } from './debts.service';
import { DebtOverdueJob } from './jobs/debt-overdue.job';
import { DebtDueNotifyJob } from './jobs/debt-due-notify.job';
import { BalanceService } from '../../common/services/balance.service';

@Module({
  controllers: [DebtsController],
  providers: [DebtsService, DebtOverdueJob, DebtDueNotifyJob, BalanceService],
  exports: [DebtsService],
})
export class DebtsModule {}
