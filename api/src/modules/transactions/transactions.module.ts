import { Module } from '@nestjs/common';
import { TransactionsController } from './transactions.controller';
import { TransactionsService } from './transactions.service';
import { RecurringTransactionJob } from './jobs/recurring-transaction.job';
import { BalanceService } from '../../common/services/balance.service';

@Module({
  controllers: [TransactionsController],
  providers: [TransactionsService, RecurringTransactionJob, BalanceService],
  exports: [TransactionsService, BalanceService],
})
export class TransactionsModule {}
