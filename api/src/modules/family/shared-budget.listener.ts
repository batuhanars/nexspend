/* eslint-disable @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access */
import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { TransactionType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { TransactionCreatedEvent } from '../../common/events/transaction.events';

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
    if (!event.categoryId) return;

    try {
      const memberships = await this.prisma.familyMember.findMany({
        where: { userId: event.userId },
        select: { groupId: true },
      });

      if (memberships.length === 0) return;

      for (const { groupId } of memberships) {
        const sharedBudget = await this.prisma.sharedBudget.findFirst({
          where: { groupId, categoryId: event.categoryId, isActive: true },
          include: {
            group: {
              include: {
                members: { select: { userId: true } },
              },
            },
            category: { select: { name: true } },
          },
        });

        if (!sharedBudget) continue;

        await this.prisma.$transaction(async (tx) => {
          await tx.sharedExpense.create({
            data: {
              sharedBudgetId: sharedBudget.id,
              transactionId: event.transactionId,
              userId: event.userId,
              amount: event.amount,
            },
          });
          await tx.sharedBudget.update({
            where: { id: sharedBudget.id },
            data: { spent: { increment: event.amount } },
          });
        });

        const user = await this.prisma.user.findUnique({
          where: { id: event.userId },
          select: { fullName: true },
        });

        const otherMembers = sharedBudget.group.members.filter(
          (m) => m.userId !== event.userId,
        );

        for (const m of otherMembers) {
          await this.notifications.sendToUser(
            m.userId,
            'Ortak Bütçe',
            `${user?.fullName ?? 'Bir üye'} ${sharedBudget.category.name} kategorisinde ₺${event.amount.toFixed(2)} harcadı`,
          );
        }
      }
    } catch (err) {
      this.logger.error(
        `SharedBudget listener hatası [tx:${event.transactionId}]: ${(err as Error).message}`,
      );
    }
  }
}
