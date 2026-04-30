import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { PrismaService } from '../../../prisma/prisma.service';
import { TransactionCreatedEvent } from '../../../common/events/transaction.events';

@Injectable()
export class RecurringTransactionJob {
  private readonly logger = new Logger(RecurringTransactionJob.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  @Cron('5 0 * * *') // Her gün 00:05
  async run() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const dueTemplates = await this.prisma.recurringTransaction.findMany({
      where: {
        isActive: true,
        nextRunDate: { lte: today },
        OR: [{ endDate: null }, { endDate: { gte: today } }],
      },
    });

    this.logger.log(`${dueTemplates.length} tekrarlayan işlem işlenecek`);

    for (const template of dueTemplates) {
      try {
        await this.processTemplate(template);
      } catch (err) {
        this.logger.error(`Şablon ${template.id} işlenemedi: ${err}`);
      }
    }
  }

  private async processTemplate(template: any) {
    const nextRunDate = this.calcNextRunDate(
      new Date(template.nextRunDate),
      template.frequency,
    );

    await this.prisma.$transaction(async (tx) => {
      const transaction = await tx.transaction.create({
        data: {
          userId: template.userId,
          accountId: template.accountId,
          categoryId: template.categoryId,
          type: template.type,
          amount: template.amount,
          title: template.title,
          note: template.note,
          transactionDate: new Date(template.nextRunDate),
          source: 'RECURRING',
        },
      });

      if (template.type === 'INCOME') {
        await tx.account.update({
          where: { id: template.accountId },
          data: { balance: { increment: Number(template.amount) } },
        });
      } else if (template.type === 'EXPENSE') {
        await tx.account.update({
          where: { id: template.accountId },
          data: { balance: { decrement: Number(template.amount) } },
        });
      }

      const shouldStop =
        template.endDate && nextRunDate > new Date(template.endDate);

      await tx.recurringTransaction.update({
        where: { id: template.id },
        data: {
          nextRunDate,
          isActive: !shouldStop,
        },
      });

      this.eventEmitter.emit(
        'transaction.created',
        new TransactionCreatedEvent(
          transaction.id,
          template.userId,
          template.categoryId,
          template.type,
          'RECURRING',
          Number(template.amount),
          new Date(template.nextRunDate),
        ),
      );
    });
  }

  private calcNextRunDate(from: Date, frequency: string): Date {
    const d = new Date(from);
    switch (frequency) {
      case 'DAILY':
        d.setDate(d.getDate() + 1);
        break;
      case 'WEEKLY':
        d.setDate(d.getDate() + 7);
        break;
      case 'MONTHLY':
        d.setMonth(d.getMonth() + 1);
        break;
      case 'YEARLY':
        d.setFullYear(d.getFullYear() + 1);
        break;
    }
    return d;
  }
}
