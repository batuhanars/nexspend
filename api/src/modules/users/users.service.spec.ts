/* eslint-disable */
import { NotFoundException } from '@nestjs/common';
import { TransactionType } from '@prisma/client';
import { UsersService } from './users.service';
import * as fs from 'fs';

// Yalnız dosya silme fonksiyonlarını mock'la; gerçek fs korunur
// (bcrypt'in native yükleyicisi fs.readdirSync'e ihtiyaç duyar).
jest.mock('fs', () => {
  const actual = jest.requireActual('fs');
  return {
    ...actual,
    existsSync: jest.fn(actual.existsSync),
    unlinkSync: jest.fn(),
  };
});

// ──────────────────────────────────────────────────────────────────────────────
// Prisma mock
// ──────────────────────────────────────────────────────────────────────────────

const mockPrisma = {
  user: {
    findUnique: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  },
  receipt: {
    findMany: jest.fn(),
    deleteMany: jest.fn(),
  },
  transaction: {
    findMany: jest.fn(),
    deleteMany: jest.fn(),
    aggregate: jest.fn(),
  },
  budget: {
    deleteMany: jest.fn(),
  },
  recurringTransaction: {
    deleteMany: jest.fn(),
  },
  subscription: {
    deleteMany: jest.fn(),
  },
  insight: {
    deleteMany: jest.fn(),
  },
  debt: {
    deleteMany: jest.fn(),
  },
  tag: {
    deleteMany: jest.fn(),
  },
  merchantCategoryMap: {
    deleteMany: jest.fn(),
  },
  account: {
    deleteMany: jest.fn(),
  },
  sharedBudget: {
    update: jest.fn(),
  },
  category: {
    deleteMany: jest.fn(),
  },
  $transaction: jest.fn(),
};

const USER_ID = 'user-1';

const baseUser = {
  id: USER_ID,
  fullName: 'Test Kullanıcı',
  email: 'test@example.com',
  passwordHash: 'hash',
  avatarUrl: null,
  currency: 'TRY',
  language: 'tr',
  biometricEnabled: false,
  notificationsEnabled: true,
  fcmToken: null,
  googleId: null,
  createdAt: new Date(),
  updatedAt: new Date(),
};

// ──────────────────────────────────────────────────────────────────────────────
// Test Suite
// ──────────────────────────────────────────────────────────────────────────────

describe('UsersService', () => {
  let service: UsersService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new UsersService(mockPrisma as any);

    // $transaction: callback pattern — tx = aynı mock
    mockPrisma.$transaction.mockImplementation(async (fn: any) => {
      if (typeof fn === 'function') {
        return fn(mockPrisma);
      }
      return Promise.all(fn);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // resetData
  // ──────────────────────────────────────────────────────────────────────────

  describe('resetData', () => {
    beforeEach(() => {
      // user bulunuyor
      mockPrisma.user.findUnique.mockResolvedValue(baseUser);

      // fiş görseli yok varsayılan
      mockPrisma.receipt.findMany.mockResolvedValue([]);

      // sharedBudget transaction yok varsayılan
      mockPrisma.transaction.findMany.mockResolvedValue([]);

      // tüm deleteMany başarılı
      mockPrisma.receipt.deleteMany.mockResolvedValue({ count: 0 });
      mockPrisma.transaction.deleteMany.mockResolvedValue({ count: 0 });
      mockPrisma.budget.deleteMany.mockResolvedValue({ count: 0 });
      mockPrisma.recurringTransaction.deleteMany.mockResolvedValue({ count: 0 });
      mockPrisma.subscription.deleteMany.mockResolvedValue({ count: 0 });
      mockPrisma.insight.deleteMany.mockResolvedValue({ count: 0 });
      mockPrisma.debt.deleteMany.mockResolvedValue({ count: 0 });
      mockPrisma.tag.deleteMany.mockResolvedValue({ count: 0 });
      mockPrisma.merchantCategoryMap.deleteMany.mockResolvedValue({ count: 0 });
      mockPrisma.account.deleteMany.mockResolvedValue({ count: 0 });
      mockPrisma.sharedBudget.update.mockResolvedValue({});
    });

    it('başarıyla tamamlanır ve doğru mesaj döner', async () => {
      const result = await service.resetData(USER_ID);
      expect(result).toEqual({ message: 'Verileriniz sıfırlandı.' });
    });

    it('user bulunamazsa NotFoundException fırlatır', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);
      await expect(service.resetData(USER_ID)).rejects.toThrow(NotFoundException);
    });

    it('user.delete ÇAĞRILMAZ — kullanıcı satırı korunur', async () => {
      await service.resetData(USER_ID);
      expect(mockPrisma.user.delete).not.toHaveBeenCalled();
    });

    it('category.deleteMany ÇAĞRILMAZ — kategoriler korunur', async () => {
      await service.resetData(USER_ID);
      expect(mockPrisma.category.deleteMany).not.toHaveBeenCalled();
    });

    it('kişisel modellerin deleteMany çağrılır', async () => {
      await service.resetData(USER_ID);

      expect(mockPrisma.receipt.deleteMany).toHaveBeenCalledWith({ where: { userId: USER_ID } });
      expect(mockPrisma.transaction.deleteMany).toHaveBeenCalledWith({ where: { userId: USER_ID } });
      expect(mockPrisma.budget.deleteMany).toHaveBeenCalledWith({ where: { userId: USER_ID } });
      expect(mockPrisma.recurringTransaction.deleteMany).toHaveBeenCalledWith({ where: { userId: USER_ID } });
      expect(mockPrisma.subscription.deleteMany).toHaveBeenCalledWith({ where: { userId: USER_ID } });
      expect(mockPrisma.insight.deleteMany).toHaveBeenCalledWith({ where: { userId: USER_ID } });
      expect(mockPrisma.debt.deleteMany).toHaveBeenCalledWith({ where: { userId: USER_ID } });
      expect(mockPrisma.tag.deleteMany).toHaveBeenCalledWith({ where: { userId: USER_ID } });
      expect(mockPrisma.merchantCategoryMap.deleteMany).toHaveBeenCalledWith({ where: { userId: USER_ID } });
      expect(mockPrisma.account.deleteMany).toHaveBeenCalledWith({ where: { userId: USER_ID } });
    });

    it('SharedBudget.spent etkilenen bütçeler için yeniden hesaplanır', async () => {
      const BUDGET_ID = 'budget-shared-1';
      // Kullanıcının bir shared expense transaction'ı var
      mockPrisma.transaction.findMany.mockResolvedValue([
        { sharedBudgetId: BUDGET_ID },
      ]);
      // Kalan transaction toplamı (başka kullanıcıdan)
      mockPrisma.transaction.aggregate.mockResolvedValue({
        _sum: { amount: 250 },
      });

      await service.resetData(USER_ID);

      // aggregate çağrıldı mı?
      expect(mockPrisma.transaction.aggregate).toHaveBeenCalledWith({
        where: {
          sharedBudgetId: BUDGET_ID,
          type: TransactionType.EXPENSE,
        },
        _sum: { amount: true },
      });

      // sharedBudget.update ile yeni spent set edildi mi?
      expect(mockPrisma.sharedBudget.update).toHaveBeenCalledWith({
        where: { id: BUDGET_ID },
        data: { spent: 250 },
      });
    });

    it('SharedExpense yoksa sharedBudget.update ÇAĞRILMAZ', async () => {
      mockPrisma.transaction.findMany.mockResolvedValue([]);
      await service.resetData(USER_ID);
      expect(mockPrisma.sharedBudget.update).not.toHaveBeenCalled();
    });

    it('fiş görsel URL\'leri için deleteLocalFile çağrılır (disk silme)', async () => {
      const imageUrl = '/uploads/receipts/test-receipt.jpg';
      mockPrisma.receipt.findMany.mockResolvedValue([{ imageUrl }]);
      (fs.existsSync as jest.Mock).mockReturnValue(true);

      await service.resetData(USER_ID);

      expect(fs.unlinkSync).toHaveBeenCalledTimes(1);
    });

    it('fiş görseli yoksa disk silme çağrılmaz', async () => {
      mockPrisma.receipt.findMany.mockResolvedValue([]);

      await service.resetData(USER_ID);

      expect(fs.unlinkSync).not.toHaveBeenCalled();
    });

    it('aynı sharedBudgetId birden fazla transaction\'da varsa tek kez günceller', async () => {
      const BUDGET_ID = 'budget-shared-2';
      mockPrisma.transaction.findMany.mockResolvedValue([
        { sharedBudgetId: BUDGET_ID },
        { sharedBudgetId: BUDGET_ID },
      ]);
      mockPrisma.transaction.aggregate.mockResolvedValue({
        _sum: { amount: 100 },
      });

      await service.resetData(USER_ID);

      // Set mantığıyla tek kez çağrılmalı
      expect(mockPrisma.sharedBudget.update).toHaveBeenCalledTimes(1);
    });
  });
});
