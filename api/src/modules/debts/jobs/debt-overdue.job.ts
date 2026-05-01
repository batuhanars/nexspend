import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { DebtsService } from '../debts.service';

@Injectable()
export class DebtOverdueJob {
  private readonly logger = new Logger(DebtOverdueJob.name);

  constructor(private readonly debtsService: DebtsService) {}

  @Cron('10 0 * * *') // Her gün 00:10
  async run() {
    this.logger.log('Vadesi geçmiş borç kontrolü başladı');
    await this.debtsService.markOverdue();
  }
}
