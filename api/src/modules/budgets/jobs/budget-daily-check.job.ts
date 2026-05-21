import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { BudgetsService } from '../budgets.service';

@Injectable()
export class BudgetDailyCheckJob {
  private readonly logger = new Logger(BudgetDailyCheckJob.name);

  constructor(private readonly budgetsService: BudgetsService) {}

  @Cron('30 0 * * *') // Her gün 00:30 — önce arşivle, sonra spent recompute
  async run() {
    this.logger.log('Bütçe dönem sonu kontrolü başladı');
    const archiveStats = await this.budgetsService.archiveExpired();
    this.logger.log(
      `Arşivleme — kişisel: ${archiveStats.personal}, ortak: ${archiveStats.shared}`,
    );
    await this.budgetsService.recomputeAllActive();
    this.logger.log('Günlük bütçe kontrolü tamamlandı');
  }
}
