/* eslint-disable @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access */
import { Injectable } from '@nestjs/common';
import { TransactionType } from '@prisma/client';

@Injectable()
export class BalanceService {
  /**
   * Bakiyeyi transaction tipi yönünde günceller.
   * `client` olarak hem PrismaService hem de $transaction callback'inden gelen tx geçirilebilir.
   */
  async apply(
    client: any,
    accountId: string,
    type: TransactionType,
    amount: number,
    transferToAccountId?: string,
  ): Promise<void> {
    if (type === TransactionType.INCOME) {
      await client.account.update({
        where: { id: accountId },
        data: { balance: { increment: amount } },
      });
    } else if (type === TransactionType.EXPENSE) {
      await client.account.update({
        where: { id: accountId },
        data: { balance: { decrement: amount } },
      });
    } else if (type === TransactionType.TRANSFER && transferToAccountId) {
      await client.account.update({
        where: { id: accountId },
        data: { balance: { decrement: amount } },
      });
      await client.account.update({
        where: { id: transferToAccountId },
        data: { balance: { increment: amount } },
      });
    }
  }

  /**
   * `apply`'ın tersini uygular (geri alma / rollback).
   */
  async revert(
    client: any,
    accountId: string,
    type: TransactionType,
    amount: number,
    transferToAccountId?: string,
  ): Promise<void> {
    if (type === TransactionType.INCOME) {
      await client.account.update({
        where: { id: accountId },
        data: { balance: { decrement: amount } },
      });
    } else if (type === TransactionType.EXPENSE) {
      await client.account.update({
        where: { id: accountId },
        data: { balance: { increment: amount } },
      });
    } else if (type === TransactionType.TRANSFER && transferToAccountId) {
      await client.account.update({
        where: { id: accountId },
        data: { balance: { increment: amount } },
      });
      await client.account.update({
        where: { id: transferToAccountId },
        data: { balance: { decrement: amount } },
      });
    }
  }
}
