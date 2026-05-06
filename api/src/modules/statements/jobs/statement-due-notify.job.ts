import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { StatementsService } from '../statements.service';

@Injectable()
export class StatementDueNotifyJob {
  private readonly logger = new Logger(StatementDueNotifyJob.name);

  constructor(private readonly statementsService: StatementsService) {}

  /// Her gün 09:00. Eşikler: vade -3 gün / vade günü / +1 / +3 / +7 gün geçen.
  /// Cron günde bir çalıştığı için aynı eşikte aynı statement bir kez bildirim
  /// alır; ek state tutmuyoruz.
  @Cron('0 9 * * *')
  async run() {
    try {
      const sent = await this.statementsService.notifyDueStatements();
      if (sent > 0) {
        this.logger.log(`${sent} bildirim gönderildi`);
      }
    } catch (err) {
      this.logger.error(
        `Vade bildirimi hatası: ${(err as Error).message}`,
        (err as Error).stack,
      );
    }
  }
}
