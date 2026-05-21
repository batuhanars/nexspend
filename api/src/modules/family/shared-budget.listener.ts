import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { TransactionType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  TransactionCreatedEvent,
  TransactionUpdatedEvent,
  TransactionDeletedEvent,
} from '../../common/events/transaction.events';

@Injectable()
export class SharedBudgetListener {
  private readonly logger = new Logger(SharedBudgetListener.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

  @OnEvent('transaction.created')
  async handleTransactionCreated(
    event: TransactionCreatedEvent,
  ): Promise<void> {
    if (event.type !== TransactionType.EXPENSE) return;
    if (!event.sharedBudgetId) return; // Sadece opt-in
    await this.applyToBudget(event.sharedBudgetId, event.userId, event.amount);
  }

  @OnEvent('transaction.updated')
  async handleTransactionUpdated(
    event: TransactionUpdatedEvent,
  ): Promise<void> {
    // Eski ortak bütçeyi geri al
    if (event.oldSharedBudgetId && event.oldType === TransactionType.EXPENSE) {
      await this.revertFromBudget(event.oldSharedBudgetId, event.oldAmount);
    }
    // Yeni ortak bütçeye uygula
    if (event.newSharedBudgetId && event.newType === TransactionType.EXPENSE) {
      await this.applyToBudget(
        event.newSharedBudgetId,
        event.userId,
        event.newAmount,
      );
    }
  }

  @OnEvent('transaction.deleted')
  async handleTransactionDeleted(
    event: TransactionDeletedEvent,
  ): Promise<void> {
    if (event.type !== TransactionType.EXPENSE) return;
    if (!event.sharedBudgetId) return;
    await this.revertFromBudget(event.sharedBudgetId, event.amount);
  }

  private async applyToBudget(
    sharedBudgetId: string,
    actingUserId: string,
    amount: number,
  ) {
    try {
      const budget = await this.prisma.sharedBudget.findUnique({
        where: { id: sharedBudgetId },
        include: {
          group: {
            include: { members: { select: { userId: true } } },
          },
          category: { select: { name: true } },
        },
      });
      if (!budget) return;

      await this.prisma.sharedBudget.update({
        where: { id: sharedBudgetId },
        data: { spent: { increment: amount } },
      });

      const user = await this.prisma.user.findUnique({
        where: { id: actingUserId },
        select: { fullName: true },
      });
      const otherMembers = budget.group.members.filter(
        (m) => m.userId !== actingUserId,
      );

      for (const m of otherMembers) {
        await this.notifications.sendToUser(
          m.userId,
          'Ortak Bütçe',
          `${user?.fullName ?? 'Bir üye'} ${budget.category.name} kategorisinde ₺${amount.toFixed(2)} harcadı`,
        );
      }
    } catch (err) {
      this.logger.error(
        `SharedBudget apply hatasi [budget:${sharedBudgetId}]: ${(err as Error).message}`,
      );
    }
  }

  private async revertFromBudget(sharedBudgetId: string, amount: number) {
    try {
      await this.prisma.sharedBudget.update({
        where: { id: sharedBudgetId },
        data: { spent: { decrement: amount } },
      });
    } catch (err) {
      this.logger.error(
        `SharedBudget revert hatasi [budget:${sharedBudgetId}]: ${(err as Error).message}`,
      );
    }
  }
}
