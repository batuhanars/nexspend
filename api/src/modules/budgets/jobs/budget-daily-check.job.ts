import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../../../prisma/prisma.service';
import { BudgetsService } from '../budgets.service';

@Injectable()
export class BudgetDailyCheckJob {
  private readonly logger = new Logger(BudgetDailyCheckJob.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly budgetsService: BudgetsService,
  ) {}

  @Cron('10 9 * * *') // Her gün 09:10
  async run() {
    this.logger.log('Günlük bütçe kontrolü başladı');

    const activeBudgets = await this.prisma.budget.findMany({
      where: { isActive: true },
      select: { userId: true, categoryId: true },
      distinct: ['userId', 'categoryId'],
    });

    this.logger.log(`${activeBudgets.length} benzersiz bütçe kontrolü yapılacak`);

    for (const { userId, categoryId } of activeBudgets) {
      try {
        await this.budgetsService.recalculateForCategory(userId, categoryId);
      } catch (err) {
        this.logger.error(`userId=${userId} categoryId=${categoryId} güncellenemedi: ${err}`);
      }
    }

    this.logger.log('Günlük bütçe kontrolü tamamlandı');
  }
}
