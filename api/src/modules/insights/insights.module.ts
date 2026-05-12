import { Module } from '@nestjs/common';
import { InsightsController } from './insights.controller';
import { InsightService } from './insight.service';
import { InsightRulesService } from './insight-rules.service';
import { MonthlyInsightJob } from './jobs/monthly-insight.job';
import { InsightCleanupJob } from './jobs/insight-cleanup.job';

@Module({
  controllers: [InsightsController],
  providers: [
    InsightService,
    InsightRulesService,
    MonthlyInsightJob,
    InsightCleanupJob,
  ],
  exports: [InsightService],
})
export class InsightsModule {}
