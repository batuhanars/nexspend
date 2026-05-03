import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { DebtsService } from '../debts.service';
import { NotificationsService } from '../../notifications/notifications.service';

@Injectable()
export class DebtDueNotifyJob {
  private readonly logger = new Logger(DebtDueNotifyJob.name);

  constructor(
    private readonly debtsService: DebtsService,
    private readonly notifications: NotificationsService,
  ) {}

  @Cron('5 9 * * *') // Her gün 09:05
  async run() {
    const dueTomorrow = await this.debtsService.getDueTomorrow();
    if (dueTomorrow.length === 0) return;

    this.logger.log(`${dueTomorrow.length} borç yarın vadesi dolacak`);

    for (const debt of dueTomorrow) {
      this.logger.log(
        `[Bildirim] ${debt.user.fullName} — borç vadesi yarın: ${debt.personName}`,
      );
      await this.notifications.sendToUser(
        debt.userId,
        'Borç Vadesi Yaklaşıyor',
        `${debt.personName} borcunun vadesi yarın doluyor.`,
      );
    }
  }
}
