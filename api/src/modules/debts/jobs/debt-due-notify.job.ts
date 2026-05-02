import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { DebtsService } from '../debts.service';

@Injectable()
export class DebtDueNotifyJob {
  private readonly logger = new Logger(DebtDueNotifyJob.name);

  constructor(private readonly debtsService: DebtsService) {}

  @Cron('5 9 * * *') // Her gün 09:05
  async run() {
    const dueTomorrow = await this.debtsService.getDueTomorrow();
    if (dueTomorrow.length === 0) return;

    this.logger.log(`${dueTomorrow.length} borç yarın vadesi dolacak`);
    // TODO: FCM push notification entegrasyonu eklenince buraya bildirim gönderimi gelecek
    for (const debt of dueTomorrow) {
      this.logger.log(
        `[Bildirim] ${debt.user.fullName} — borç vadesi yarın: ${debt.personName}`,
      );
    }
  }
}
