import { Injectable } from '@nestjs/common';
import { TransactionType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class BalanceService {
  constructor(private readonly prisma: PrismaService) {}

  async applyTransaction(
    accountId: string,
    type: TransactionType,
    amount: number,
    transferToAccountId?: string,
  ) {
    const ops: any[] = [];

    if (type === TransactionType.INCOME) {
      ops.push(
        this.prisma.account.update({
          where: { id: accountId },
          data: { balance: { increment: amount } },
        }),
      );
    } else if (type === TransactionType.EXPENSE) {
      ops.push(
        this.prisma.account.update({
          where: { id: accountId },
          data: { balance: { decrement: amount } },
        }),
      );
    } else if (type === TransactionType.TRANSFER && transferToAccountId) {
      ops.push(
        this.prisma.account.update({
          where: { id: accountId },
          data: { balance: { decrement: amount } },
        }),
        this.prisma.account.update({
          where: { id: transferToAccountId },
          data: { balance: { increment: amount } },
        }),
      );
    }

    return this.prisma.$transaction(ops);
  }

  async revertTransaction(
    accountId: string,
    type: TransactionType,
    amount: number,
    transferToAccountId?: string,
  ) {
    // applyTransaction'ın tersini uygular
    const reverseType =
      type === TransactionType.INCOME
        ? TransactionType.EXPENSE
        : type === TransactionType.EXPENSE
          ? TransactionType.INCOME
          : TransactionType.TRANSFER;

    return this.applyTransaction(
      accountId,
      reverseType,
      amount,
      transferToAccountId,
    );
  }
}
