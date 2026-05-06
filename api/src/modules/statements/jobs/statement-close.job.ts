import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { StatementsService } from '../statements.service';

@Injectable()
export class StatementCloseJob {
  private readonly logger = new Logger(StatementCloseJob.name);

  constructor(private readonly statementsService: StatementsService) {}

  @Cron('30 0 * * *') // Her gün 00:30
  async run() {
    this.logger.log('Kredi kartı ekstre kapatma işi başladı');
    try {
      const closed = await this.statementsService.closeStatementsForDate();
      this.logger.log(`${closed} ekstre kapatıldı`);
    } catch (err) {
      this.logger.error(
        `Ekstre kapatma hatası: ${(err as Error).message}`,
        (err as Error).stack,
      );
    }
  }
}
