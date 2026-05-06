import { Module } from '@nestjs/common';
import { StatementsController } from './statements.controller';
import { StatementsService } from './statements.service';
import { StatementCloseJob } from './jobs/statement-close.job';
import { StatementOverdueJob } from './jobs/statement-overdue.job';
import { BalanceService } from '../../common/services/balance.service';

@Module({
  controllers: [StatementsController],
  providers: [
    StatementsService,
    StatementCloseJob,
    StatementOverdueJob,
    BalanceService,
  ],
  exports: [StatementsService],
})
export class StatementsModule {}
