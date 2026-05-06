import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { StatementsService } from '../statements.service';

@Injectable()
export class StatementOverdueJob {
  private readonly logger = new Logger(StatementOverdueJob.name);

  constructor(private readonly statementsService: StatementsService) {}

  @Cron('35 0 * * *') // Her gün 00:35 — kapatma job'ından sonra çalışsın
  async run() {
    try {
      const count = await this.statementsService.markOverdue();
      if (count > 0)
        this.logger.log(`${count} ekstre OVERDUE olarak güncellendi`);
    } catch (err) {
      this.logger.error(
        `Overdue işaretleme hatası: ${(err as Error).message}`,
        (err as Error).stack,
      );
    }
  }
}
