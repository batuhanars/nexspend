import { Module } from '@nestjs/common';
import { BudgetsController } from './budgets.controller';
import { BudgetsService } from './budgets.service';
import { BudgetDailyCheckJob } from './jobs/budget-daily-check.job';

@Module({
  controllers: [BudgetsController],
  providers: [BudgetsService, BudgetDailyCheckJob],
  exports: [BudgetsService],
})
export class BudgetsModule {}
