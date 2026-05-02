import { TransactionType, TransactionSource } from '@prisma/client';

export class TransactionCreatedEvent {
  constructor(
    public readonly transactionId: string,
    public readonly userId: string,
    public readonly accountId: string,
    public readonly categoryId: string | null,
    public readonly type: TransactionType,
    public readonly source: TransactionSource,
    public readonly amount: number,
    public readonly transactionDate: Date,
  ) {}
}

export class TransactionUpdatedEvent {
  constructor(
    public readonly transactionId: string,
    public readonly userId: string,
    public readonly oldCategoryId: string | null,
    public readonly newCategoryId: string | null,
    public readonly oldType: TransactionType,
    public readonly newType: TransactionType,
    public readonly oldAmount: number,
    public readonly newAmount: number,
    public readonly transactionDate: Date,
  ) {}
}

export class TransactionDeletedEvent {
  constructor(
    public readonly transactionId: string,
    public readonly userId: string,
    public readonly categoryId: string | null,
    public readonly type: TransactionType,
    public readonly amount: number,
    public readonly transactionDate: Date,
  ) {}
}
