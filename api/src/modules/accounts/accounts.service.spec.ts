/* eslint-disable */
import { NotFoundException } from '@nestjs/common';
import { AccountType, TransactionType } from '@prisma/client';
import { AccountsService } from './accounts.service';

const mockPrisma = {
  account: {
    findMany: jest.fn(),
    findFirst: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
  },
  transaction: {
    findMany: jest.fn(),
    count: jest.fn(),
    aggregate: jest.fn(),
    groupBy: jest.fn(),
  },
  category: {
    findUnique: jest.fn(),
  },
  $transaction: jest.fn(),
};

const mockEventEmitter = { emit: jest.fn() };

const USER_ID = 'user-1';
const ACCOUNT_ID = 'acc-1';

const baseAccount = {
  id: ACCOUNT_ID,
  userId: USER_ID,
  name: 'Ziraat',
  type: AccountType.BANK,
  balance: 5000,
  creditLimit: null,
  icon: 'bank',
  color: '#1976D2',
  isDefault: true,
  isArchived: false,
  statementDay: null,
  paymentDueDay: null,
  createdAt: new Date('2026-01-01'),
  updatedAt: new Date('2026-01-01'),
};

describe('AccountsService', () => {
  let service: AccountsService;

  beforeEach(() => {
    service = new AccountsService(mockPrisma as any);
    (service as any).eventEmitter = mockEventEmitter;
    jest.clearAllMocks();
  });

  // ─── getAnalytics ─────────────────────────────────────────────────────────────

  describe('getAnalytics()', () => {
    beforeEach(() => {
      mockPrisma.transaction.aggregate.mockResolvedValue({
        _sum: { amount: 1000 },
      });
      mockPrisma.transaction.groupBy.mockResolvedValue([]);
    });

    it('standart hesap için income/expense döner ve isCreditCard false', async () => {
      mockPrisma.account.findFirst.mockResolvedValue(baseAccount);

      const result = await service.getAnalytics(USER_ID, ACCOUNT_ID);

      expect(result.isCreditCard).toBe(false);
      expect(result.months).toHaveLength(6);
      expect(result.months[0]).toHaveProperty('income');
      expect(result.months[0]).toHaveProperty('expense');
      expect(result.months[0]).not.toHaveProperty('payment');
      expect(result.months[0]).not.toHaveProperty('spend');
    });

    it('kredi kartı için payment/spend döner ve isCreditCard true', async () => {
      const ccAccount = {
        ...baseAccount,
        type: AccountType.CREDIT_CARD,
        creditLimit: 10000,
      };
      mockPrisma.account.findFirst.mockResolvedValue(ccAccount);

      const result = await service.getAnalytics(USER_ID, ACCOUNT_ID);

      expect(result.isCreditCard).toBe(true);
      expect(result.months).toHaveLength(6);
      expect(result.months[0]).toHaveProperty('payment');
      expect(result.months[0]).toHaveProperty('spend');
      expect(result.months[0]).not.toHaveProperty('income');
      expect(result.months[0]).not.toHaveProperty('expense');
    });

    it('kredi kartı payment → TRANSFER toAccountId filtresi kullanır', async () => {
      const ccAccount = {
        ...baseAccount,
        type: AccountType.CREDIT_CARD,
        creditLimit: 10000,
      };
      mockPrisma.account.findFirst.mockResolvedValue(ccAccount);
      mockPrisma.transaction.aggregate.mockResolvedValue({
        _sum: { amount: 500 },
      });

      const result = await service.getAnalytics(USER_ID, ACCOUNT_ID);

      const aggregateCalls = mockPrisma.transaction.aggregate.mock.calls;
      const paymentCall = aggregateCalls.find(
        ([arg]) => arg.where?.transferToAccountId === ACCOUNT_ID && arg.where?.type === 'TRANSFER',
      );
      expect(paymentCall).toBeDefined();
      expect(result.months[0].payment).toBe(500);
    });

    it('standart hesap income → INCOME accountId filtresi kullanır', async () => {
      mockPrisma.account.findFirst.mockResolvedValue(baseAccount);
      mockPrisma.transaction.aggregate.mockResolvedValue({
        _sum: { amount: 3000 },
      });

      await service.getAnalytics(USER_ID, ACCOUNT_ID);

      const aggregateCalls = mockPrisma.transaction.aggregate.mock.calls;
      const incomeCall = aggregateCalls.find(
        ([arg]) => arg.where?.accountId === ACCOUNT_ID && arg.where?.type === 'INCOME',
      );
      expect(incomeCall).toBeDefined();
    });

    it('topCategories listesini döner', async () => {
      mockPrisma.account.findFirst.mockResolvedValue(baseAccount);
      mockPrisma.transaction.groupBy.mockResolvedValue([
        { categoryId: 'cat-1', _sum: { amount: 500 } },
      ]);
      mockPrisma.category.findUnique.mockResolvedValue({
        id: 'cat-1',
        name: 'Market',
        icon: 'shopping_cart',
        color: '#F44336',
      });

      const result = await service.getAnalytics(USER_ID, ACCOUNT_ID);

      expect(result.topCategories).toHaveLength(1);
      expect(result.topCategories[0].name).toBe('Market');
      expect(result.topCategories[0].amount).toBe(500);
    });

    it('hesap bulunamazsa NotFoundException fırlatır', async () => {
      mockPrisma.account.findFirst.mockResolvedValue(null);

      await expect(
        service.getAnalytics(USER_ID, 'nonexistent'),
      ).rejects.toThrow(NotFoundException);
    });
  });
});
