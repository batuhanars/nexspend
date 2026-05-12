import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../../../prisma/prisma.service';

@Injectable()
export class InsightCleanupJob {
  private readonly logger = new Logger(InsightCleanupJob.name);

  constructor(private readonly prisma: PrismaService) {}

  @Cron('0 2 1 * *')
  async run(): Promise<void> {
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

    const result = await this.prisma.insight.deleteMany({
      where: {
        isDismissed: true,
        createdAt: { lt: sixMonthsAgo },
      },
    });

    this.logger.log(`Insight temizleme: ${result.count} kayıt silindi`);
  }
}
