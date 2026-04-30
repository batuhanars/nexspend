import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaClient } from '../../generated/prisma/client.js';
import { PrismaMariaDb } from '@prisma/adapter-mariadb';

type Client = InstanceType<typeof PrismaClient>;

@Injectable()
export class PrismaService implements OnModuleInit, OnModuleDestroy {
  private readonly _client: Client;

  constructor(configService: ConfigService) {
    const adapter = new PrismaMariaDb(
      configService.get<string>('database.url') as string,
    );
    this._client = new (PrismaClient as any)({ adapter });
  }

  async onModuleInit() {
    await (this._client as any).$connect();
  }

  async onModuleDestroy() {
    await (this._client as any).$disconnect();
  }

  // =============================================
  // Model Accessors (27 model)
  // =============================================

  get user() { return this._client.user; }
  get passwordResetToken() { return this._client.passwordResetToken; }
  get account() { return this._client.account; }
  get category() { return this._client.category; }
  get tag() { return this._client.tag; }
  get transactionTag() { return this._client.transactionTag; }
  get transaction() { return this._client.transaction; }
  get recurringTransaction() { return this._client.recurringTransaction; }
  get budget() { return this._client.budget; }
  get debt() { return this._client.debt; }
  get debtInstallment() { return this._client.debtInstallment; }
  get debtPayment() { return this._client.debtPayment; }
  get subscription() { return this._client.subscription; }
  get receipt() { return this._client.receipt; }
  get receiptItem() { return this._client.receiptItem; }
  get merchantCategoryMap() { return this._client.merchantCategoryMap; }
  get inflationRate() { return this._client.inflationRate; }
  get categoryInflationMap() { return this._client.categoryInflationMap; }
  get portfolioAsset() { return this._client.portfolioAsset; }
  get portfolioTx() { return this._client.portfolioTx; }
  get exchangeRate() { return this._client.exchangeRate; }
  get insight() { return this._client.insight; }
  get familyGroup() { return this._client.familyGroup; }
  get familyMember() { return this._client.familyMember; }
  get familyInvite() { return this._client.familyInvite; }
  get sharedBudget() { return this._client.sharedBudget; }
  get sharedExpense() { return this._client.sharedExpense; }

  // =============================================
  // Utility Methods
  // =============================================

  readonly $transaction = (...args: any[]) =>
    (this._client as any).$transaction(...args);

  $queryRaw(...args: any[]) {
    return (this._client as any).$queryRaw(...args);
  }

  $executeRaw(...args: any[]) {
    return (this._client as any).$executeRaw(...args);
  }
}
