/* eslint-disable */
import { NotFoundException, BadRequestException } from '@nestjs/common';
import {
  SubscriptionPeriod,
  SubscriptionKind,
  TransactionType,
} from '@prisma/client';
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

const mockNotifications = {
  sendToUser: jest.fn(),
};

const USER_ID = 'user-1';
const SUB_ID = 'sub-1';
const ACCOUNT_ID = 'acc-1';

const baseSub = {
  id: SUB_ID,
  userId: USER_ID,
  name: 'Netflix',
  amount: 149.99,
  reminderDaysBefore: 3,
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
      mockNotifications as any,
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

    it('autoDeduct=true olsa bile oluşturmada işlem YARATMAZ (ilk kesinti yenileme tarihinde)', async () => {
      mockPrisma.subscription.create.mockResolvedValue({
        ...baseSub,
        name: 'Spotify',
        amount: 49.99,
      });

      await service.create(USER_ID, dto);

      expect(mockPrisma.subscription.create).toHaveBeenCalled();
      expect(mockPrisma.$transaction).not.toHaveBeenCalled();
      expect(mockEventEmitter.emit).not.toHaveBeenCalled();
    });

    it('abonelikte autoDeduct daima true olur (dto.autoDeduct yok sayılır)', async () => {
      mockPrisma.subscription.create.mockResolvedValue({ ...baseSub });

      await service.create(USER_ID, { ...dto, autoDeduct: false });

      expect(mockPrisma.subscription.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            kind: SubscriptionKind.SUBSCRIPTION,
            autoDeduct: true,
          }),
        }),
      );
      expect(mockPrisma.$transaction).not.toHaveBeenCalled();
    });

    it('kind=BILL ise autoDeduct false zorlanır ve ilk işlem oluşmaz', async () => {
      mockPrisma.subscription.create.mockResolvedValue({
        ...baseSub,
        name: 'Elektrik',
        kind: SubscriptionKind.BILL,
        autoDeduct: false,
      });

      await service.create(USER_ID, {
        ...dto,
        kind: SubscriptionKind.BILL,
        autoDeduct: true, // gönderilse bile yoksayılmalı
      });

      expect(mockPrisma.subscription.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            kind: SubscriptionKind.BILL,
            autoDeduct: false,
          }),
        }),
      );
      expect(mockPrisma.$transaction).not.toHaveBeenCalled();
    });

    it('SUBSCRIPTION türünde tutar yoksa BadRequestException fırlatır', async () => {
      const { amount, ...noAmount } = dto;

      await expect(service.create(USER_ID, noAmount as any)).rejects.toThrow(
        BadRequestException,
      );
      expect(mockPrisma.subscription.create).not.toHaveBeenCalled();
    });
  });

  // ─── markPaid ────────────────────────────────────────────────────────────────

  describe('markPaid()', () => {
    const billSub = {
      ...baseSub,
      name: 'Elektrik',
      kind: SubscriptionKind.BILL,
      autoDeduct: false,
      amount: 300,
    };

    it('gerçek tutarla işlem oluşturur, son ödeme tarihini ilerletir ve tahmini günceller', async () => {
      mockPrisma.subscription.findFirst.mockResolvedValue(billSub);
      mockPrisma.$transaction.mockImplementation(async (fn: any) => {
        const tx = {
          transaction: {
            create: jest
              .fn()
              .mockResolvedValue({ id: 'tx-1', type: TransactionType.EXPENSE }),
          },
        };
        return fn(tx);
      });
      mockPrisma.subscription.update.mockResolvedValue(billSub);

      await service.markPaid(USER_ID, SUB_ID, { amount: 427.5 });

      // gerçek tutar (427.5) bakiyeye uygulanmalı, tahmini (300) değil
      expect(mockBalanceService.apply).toHaveBeenCalledWith(
        expect.anything(),
        ACCOUNT_ID,
        TransactionType.EXPENSE,
        427.5,
      );
      expect(mockEventEmitter.emit).toHaveBeenCalledWith(
        'transaction.created',
        expect.any(Object),
      );
      expect(mockPrisma.subscription.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ amount: 427.5 }),
        }),
      );
    });

    it('sahip değilse NotFoundException fırlatır', async () => {
      mockPrisma.subscription.findFirst.mockResolvedValue(null);

      await expect(
        service.markPaid(USER_ID, 'bad-id', { amount: 100 }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  // ─── notifyUpcoming ────────────────────────────────────────────────────────────

  describe('notifyUpcoming()', () => {
    const daysFromNow = (n: number) => {
      const d = new Date();
      d.setHours(0, 0, 0, 0);
      d.setDate(d.getDate() + n);
      return d;
    };

    it('otomatik abonelik reminderDaysBefore gününde yenileme bildirimi gönderir', async () => {
      mockPrisma.subscription.findMany.mockResolvedValue([
        {
          ...baseSub,
          autoDeduct: true,
          reminderDaysBefore: 3,
          nextRenewal: daysFromNow(3),
        },
      ]);

      const sent = await service.notifyUpcoming();

      expect(sent).toBe(1);
      expect(mockNotifications.sendToUser).toHaveBeenCalledWith(
        USER_ID,
        'Abonelik yenileniyor',
        expect.stringContaining('3 gün'),
        expect.objectContaining({ type: 'subscription_renewal' }),
      );
    });

    it('otomatik abonelik yenileme günü (0) bildirimi gönderir', async () => {
      mockPrisma.subscription.findMany.mockResolvedValue([
        {
          ...baseSub,
          autoDeduct: true,
          reminderDaysBefore: 3,
          nextRenewal: daysFromNow(0),
        },
      ]);

      const sent = await service.notifyUpcoming();

      expect(sent).toBe(1);
      expect(mockNotifications.sendToUser).toHaveBeenCalledWith(
        USER_ID,
        'Abonelik bugün yenileniyor',
        expect.any(String),
        expect.objectContaining({ type: 'subscription_renewal' }),
      );
    });

    it('fatura, reminderDaysBefore gününde "yaklaşıyor" bildirimi gönderir', async () => {
      mockPrisma.subscription.findMany.mockResolvedValue([
        {
          ...baseSub,
          name: 'Su',
          kind: SubscriptionKind.BILL,
          autoDeduct: false,
          reminderDaysBefore: 3,
          nextRenewal: daysFromNow(3),
        },
      ]);

      const sent = await service.notifyUpcoming();

      expect(sent).toBe(1);
      expect(mockNotifications.sendToUser).toHaveBeenCalledWith(
        USER_ID,
        'Son ödeme yaklaşıyor',
        expect.any(String),
        expect.objectContaining({ type: 'subscription_bill' }),
      );
    });

    it('faturanın son ödemesi geçmişse gecikme bildirimi gönderir', async () => {
      mockPrisma.subscription.findMany.mockResolvedValue([
        {
          ...baseSub,
          name: 'Doğalgaz',
          kind: SubscriptionKind.BILL,
          autoDeduct: false,
          reminderDaysBefore: 3,
          nextRenewal: daysFromNow(-1),
        },
      ]);

      const sent = await service.notifyUpcoming();

      expect(sent).toBe(1);
      expect(mockNotifications.sendToUser).toHaveBeenCalledWith(
        USER_ID,
        'Ödeme gecikti',
        expect.any(String),
        expect.objectContaining({ type: 'subscription_bill' }),
      );
    });

    it('eşik dışındaki kayıtlar için bildirim göndermez', async () => {
      mockPrisma.subscription.findMany.mockResolvedValue([
        {
          ...baseSub,
          kind: SubscriptionKind.BILL,
          autoDeduct: false,
          reminderDaysBefore: 3,
          nextRenewal: daysFromNow(10),
        },
      ]);

      const sent = await service.notifyUpcoming();

      expect(sent).toBe(0);
      expect(mockNotifications.sendToUser).not.toHaveBeenCalled();
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
