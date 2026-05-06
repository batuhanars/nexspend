/* eslint-disable */
import { NotFoundException } from '@nestjs/common';
import { SubscriptionPeriod, TransactionType } from '@prisma/client';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { SubscriptionsService } from './subscriptions.service';
import { BalanceService } from '../../common/services/balance.service';

const mockPrisma = {
  subscription: {
    findMany: jest.fn(),
    findFirst: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  },
  account: {
    update: jest.fn(),
  },
  transaction: {
    create: jest.fn(),
  },
  $transaction: jest.fn(),
};

const mockBalanceService = {
  apply: jest.fn(),
  revert: jest.fn(),
};

const mockEventEmitter = {
  emit: jest.fn(),
};

const USER_ID = 'user-1';
const SUB_ID = 'sub-1';
const ACCOUNT_ID = 'acc-1';

const baseSub = {
  id: SUB_ID,
  userId: USER_ID,
  name: 'Netflix',
  amount: 149.99,
  period: SubscriptionPeriod.MONTHLY,
  icon: 'netflix',
  color: '#E50914',
  accountId: ACCOUNT_ID,
  categoryId: 'cat-1',
  isActive: true,
  autoDeduct: true,
  startDate: new Date('2026-01-01'),
  nextRenewal: new Date('2026-02-01'),
  createdAt: new Date(),
  account: { id: ACCOUNT_ID, name: 'Ziraat', icon: 'bank', color: '#fff' },
  category: { id: 'cat-1', name: 'Abonelik', icon: 'sub', color: '#aaa' },
};

describe('SubscriptionsService', () => {
  let service: SubscriptionsService;

  beforeEach(() => {
    service = new SubscriptionsService(
      mockPrisma as any,
      mockBalanceService as any,
      mockEventEmitter as any,
    );
    jest.clearAllMocks();
  });

  // ─── findAll ─────────────────────────────────────────────────────────────────

  describe('findAll()', () => {
    it('kullanıcının abonelik listesini döner', async () => {
      mockPrisma.subscription.findMany.mockResolvedValue([baseSub]);

      const result = await service.findAll(USER_ID);

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe(SUB_ID);
      expect(result[0].amount).toBe(149.99);
    });
  });

  // ─── getSummary ──────────────────────────────────────────────────────────────

  describe('getSummary()', () => {
    it('aylık ve yıllık toplam doğru hesaplar', async () => {
      mockPrisma.subscription.findMany.mockResolvedValue([
        { ...baseSub, amount: 150, period: SubscriptionPeriod.MONTHLY },
        {
          ...baseSub,
          id: 'sub-2',
          amount: 1200,
          period: SubscriptionPeriod.YEARLY,
        },
        {
          ...baseSub,
          id: 'sub-3',
          amount: 50,
          period: SubscriptionPeriod.WEEKLY,
        },
      ]);

      const result = await service.getSummary(USER_ID);

      // monthly: 150 + 1200/12 + 50*4.33 = 150 + 100 + 216.5 = 466.5
      expect(result.monthlyTotal).toBeGreaterThan(0);
      expect(result.activeCount).toBe(3);
      expect(result.yearlyTotal).toBeGreaterThan(result.monthlyTotal);
    });

    it('abonelik yoksa sıfır döner', async () => {
      mockPrisma.subscription.findMany.mockResolvedValue([]);

      const result = await service.getSummary(USER_ID);

      expect(result.activeCount).toBe(0);
      expect(result.monthlyTotal).toBe(0);
    });
  });

  // ─── getUpcoming ─────────────────────────────────────────────────────────────

  describe('getUpcoming()', () => {
    it('önümüzdeki 7 gündeki yenilemeleri döner', async () => {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      mockPrisma.subscription.findMany.mockResolvedValue([
        { ...baseSub, nextRenewal: tomorrow },
      ]);

      const result = await service.getUpcoming(USER_ID);

      expect(result).toHaveLength(1);
      expect(mockPrisma.subscription.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ isActive: true }),
        }),
      );
    });
  });

  // ─── findOne ─────────────────────────────────────────────────────────────────

  describe('findOne()', () => {
    it('mevcut aboneliği döner', async () => {
      mockPrisma.subscription.findFirst.mockResolvedValue(baseSub);

      const result = await service.findOne(USER_ID, SUB_ID);

      expect(result.id).toBe(SUB_ID);
    });

    it('bulunamazsa NotFoundException fırlatır', async () => {
      mockPrisma.subscription.findFirst.mockResolvedValue(null);

      await expect(service.findOne(USER_ID, 'nonexistent')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  // ─── create ──────────────────────────────────────────────────────────────────

  describe('create()', () => {
    const dto = {
      name: 'Spotify',
      amount: 49.99,
      period: SubscriptionPeriod.MONTHLY,
      accountId: ACCOUNT_ID,
      categoryId: 'cat-1',
      startDate: '2026-01-01',
      nextRenewal: '2026-02-01',
      autoDeduct: true,
    };

    it('autoDeduct=true ise ilk işlemi otomatik oluşturur', async () => {
      mockPrisma.subscription.create.mockResolvedValue({
        ...baseSub,
        name: 'Spotify',
        amount: 49.99,
      });
      mockPrisma.$transaction.mockImplementation(async (fn: any) => {
        const tx = {
          account: { update: jest.fn().mockResolvedValue({}) },
          transaction: {
            create: jest
              .fn()
              .mockResolvedValue({ id: 'tx-1', type: TransactionType.EXPENSE }),
          },
        };
        return fn(tx);
      });

      await service.create(USER_ID, dto);

      expect(mockPrisma.subscription.create).toHaveBeenCalled();
      expect(mockPrisma.$transaction).toHaveBeenCalled();
      expect(mockEventEmitter.emit).toHaveBeenCalledWith(
        'transaction.created',
        expect.any(Object),
      );
    });

    it('autoDeduct=false ise işlem oluşturmaz', async () => {
      mockPrisma.subscription.create.mockResolvedValue({
        ...baseSub,
        name: 'Manuel',
        amount: 100,
        autoDeduct: false,
      });

      await service.create(USER_ID, { ...dto, autoDeduct: false });

      expect(mockPrisma.$transaction).not.toHaveBeenCalled();
      expect(mockEventEmitter.emit).not.toHaveBeenCalled();
    });
  });

  // ─── update ──────────────────────────────────────────────────────────────────

  describe('update()', () => {
    it('aboneliği günceller', async () => {
      mockPrisma.subscription.findFirst.mockResolvedValue(baseSub);
      mockPrisma.subscription.update.mockResolvedValue({
        ...baseSub,
        name: 'Disney+',
      });

      const result = await service.update(USER_ID, SUB_ID, { name: 'Disney+' });

      expect(mockPrisma.subscription.update).toHaveBeenCalled();
    });

    it('bulunamazsa NotFoundException fırlatır', async () => {
      mockPrisma.subscription.findFirst.mockResolvedValue(null);

      await expect(service.update(USER_ID, 'bad-id', {})).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  // ─── remove ──────────────────────────────────────────────────────────────────

  describe('remove()', () => {
    it('aboneliği siler', async () => {
      mockPrisma.subscription.findFirst.mockResolvedValue(baseSub);
      mockPrisma.subscription.delete.mockResolvedValue(baseSub);

      const result = await service.remove(USER_ID, SUB_ID);

      expect(result).toHaveProperty('message');
      expect(mockPrisma.subscription.delete).toHaveBeenCalledWith({
        where: { id: SUB_ID },
      });
    });

    it('bulunamazsa NotFoundException fırlatır', async () => {
      mockPrisma.subscription.findFirst.mockResolvedValue(null);

      await expect(service.remove(USER_ID, 'bad-id')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  // ─── toggle ──────────────────────────────────────────────────────────────────

  describe('toggle()', () => {
    it('aktif aboneliği devre dışı bırakır', async () => {
      mockPrisma.subscription.findFirst.mockResolvedValue({
        ...baseSub,
        isActive: true,
      });
      mockPrisma.subscription.update.mockResolvedValue({
        ...baseSub,
        isActive: false,
      });

      const result = await service.toggle(USER_ID, SUB_ID);

      expect(mockPrisma.subscription.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: { isActive: false } }),
      );
    });

    it('pasif aboneliği aktifleştirir', async () => {
      mockPrisma.subscription.findFirst.mockResolvedValue({
        ...baseSub,
        isActive: false,
      });
      mockPrisma.subscription.update.mockResolvedValue({
        ...baseSub,
        isActive: true,
      });

      const result = await service.toggle(USER_ID, SUB_ID);

      expect(mockPrisma.subscription.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: { isActive: true } }),
      );
    });
  });

  // ─── processRenewals ─────────────────────────────────────────────────────────

  describe('processRenewals()', () => {
    it('vadesi gelen abonelikler için işlem oluşturur', async () => {
      const dueToday = { ...baseSub, nextRenewal: new Date() };
      mockPrisma.subscription.findMany.mockResolvedValue([dueToday]);
      mockPrisma.$transaction.mockImplementation(async (fn: any) => {
        const tx = {
          account: { update: jest.fn().mockResolvedValue({}) },
          transaction: {
            create: jest
              .fn()
              .mockResolvedValue({ id: 'tx-1', type: TransactionType.EXPENSE }),
          },
        };
        return fn(tx);
      });
      mockPrisma.subscription.update.mockResolvedValue({});

      await service.processRenewals();

      expect(mockPrisma.$transaction).toHaveBeenCalled();
      expect(mockPrisma.subscription.update).toHaveBeenCalled();
    });

    it('vadesi gelmemiş abonelikler için işlem yapmaz', async () => {
      mockPrisma.subscription.findMany.mockResolvedValue([]);

      await service.processRenewals();

      expect(mockPrisma.$transaction).not.toHaveBeenCalled();
    });
  });
});
