/* eslint-disable */
import {
  ConflictException,
  NotFoundException,
  UnprocessableEntityException,
  BadRequestException,
} from '@nestjs/common';
import { TransactionType } from '@prisma/client';
import { BudgetsService } from './budgets.service';
import { TransactionSource } from '@prisma/client';
import {
  TransactionCreatedEvent,
  TransactionDeletedEvent,
  TransactionUpdatedEvent,
} from '../../common/events/transaction.events';

const mockPrisma = {
  budget: {
    findMany: jest.fn(),
    findFirst: jest.fn(),
    findUnique: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  },
  sharedBudget: {
    findMany: jest.fn(),
    update: jest.fn(),
  },
  transaction: {
    aggregate: jest.fn(),
  },
  categoryInflationMap: {
    findUnique: jest.fn(),
  },
  inflationRate: {
    findMany: jest.fn(),
  },
};

const mockNotifications = { sendToUser: jest.fn() };

const USER_ID = 'user-1';
const BUDGET_ID = 'budget-1';
const CATEGORY_ID = 'cat-1';

const baseBudget = {
  id: BUDGET_ID,
  userId: USER_ID,
  categoryId: CATEGORY_ID,
  name: 'Market Bütçesi',
  amount: 3000,
  spent: 500,
  period: 'MONTHLY',
  note: null,
  smartTracking: true,
  isActive: true,
  startDate: new Date('2026-01-01'),
  endDate: new Date('2026-01-31'),
  createdAt: new Date(),
  updatedAt: new Date(),
  category: { id: CATEGORY_ID, name: 'Market', icon: 'cart', color: '#aaa' },
};

const flushSetImmediate = () => new Promise<void>((resolve) => setImmediate(resolve));

describe('BudgetsService', () => {
  let service: BudgetsService;

  beforeEach(async () => {
    // Önceki testten kalan setImmediate callback'leri flush et, sonra mock'ları temizle.
    await flushSetImmediate();
    jest.clearAllMocks();
    service = new BudgetsService(mockPrisma as any, mockNotifications as any);
  });

  // ─── findAll ─────────────────────────────────────────────────────────────────

  describe('findAll()', () => {
    it('aktif bütçe listesini döner', async () => {
      mockPrisma.budget.findMany.mockResolvedValue([baseBudget]);

      const result = await service.findAll(USER_ID);

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe(BUDGET_ID);
      expect(mockPrisma.budget.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { userId: USER_ID, isActive: true } }),
      );
    });

    it('includeArchived=true ile hem aktif hem arşiv döner', async () => {
      mockPrisma.budget.findMany.mockResolvedValue([baseBudget]);

      await service.findAll(USER_ID, true);

      expect(mockPrisma.budget.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { userId: USER_ID } }),
      );
    });
  });

  // ─── getOverview ─────────────────────────────────────────────────────────────

  describe('getOverview()', () => {
    it('toplam bütçe, harcanan ve kalan değerleri hesaplar', async () => {
      mockPrisma.budget.findMany.mockResolvedValue([
        { ...baseBudget, amount: 3000, spent: 1500 },
        { ...baseBudget, id: 'budget-2', amount: 2000, spent: 500 },
      ]);

      const result = await service.getOverview(USER_ID);

      expect(result.totalBudget).toBe(5000);
      expect(result.totalSpent).toBe(2000);
      expect(result.remaining).toBe(3000);
      expect(result.percentage).toBe(40);
    });

    it('bütçe yoksa sıfır yüzde döner', async () => {
      mockPrisma.budget.findMany.mockResolvedValue([]);

      const result = await service.getOverview(USER_ID);

      expect(result.percentage).toBe(0);
      expect(result.count).toBe(0);
    });
  });

  // ─── create ──────────────────────────────────────────────────────────────────

  describe('create()', () => {
    const dto = {
      categoryId: CATEGORY_ID,
      name: 'Yeni Bütçe',
      amount: 2000,
      startDate: '2026-02-01',
    };

    it('yeni bütçe oluşturur ve geçmiş harcamaları hesaplar', async () => {
      mockPrisma.budget.findFirst.mockResolvedValueOnce(null); // çakışma yok
      mockPrisma.budget.create.mockResolvedValue(baseBudget);
      mockPrisma.transaction.aggregate.mockResolvedValue({
        _sum: { amount: 500 },
      });
      mockPrisma.budget.update.mockResolvedValue({ ...baseBudget, spent: 500 });

      const result = await service.create(USER_ID, dto);

      expect(mockPrisma.budget.create).toHaveBeenCalled();
      expect(mockPrisma.budget.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: { spent: 500 } }),
      );
    });

    it('endDate verilmezse period bazlı auto-compute yapılır', async () => {
      mockPrisma.budget.findFirst.mockResolvedValueOnce(null);
      mockPrisma.budget.create.mockResolvedValue(baseBudget);
      mockPrisma.transaction.aggregate.mockResolvedValue({ _sum: { amount: 0 } });
      mockPrisma.budget.update.mockResolvedValue(baseBudget);

      await service.create(USER_ID, { ...dto, period: 'MONTHLY' });

      const createCall = mockPrisma.budget.create.mock.calls[0][0];
      // MONTHLY: 2026-02-01 → 2026-02-28
      expect(createCall.data.endDate).toBeDefined();
      expect(createCall.data.endDate).toBeInstanceOf(Date);
    });

    it('aynı kategoride aktif bütçe varsa ConflictException fırlatır', async () => {
      mockPrisma.budget.findFirst.mockResolvedValueOnce(baseBudget);

      await expect(service.create(USER_ID, dto)).rejects.toThrow(
        ConflictException,
      );
    });
  });

  // ─── update ──────────────────────────────────────────────────────────────────

  describe('update()', () => {
    it('bütçeyi günceller', async () => {
      mockPrisma.budget.findFirst.mockResolvedValue(baseBudget);
      mockPrisma.budget.update.mockResolvedValue({
        ...baseBudget,
        amount: 4000,
      });

      const result = await service.update(USER_ID, BUDGET_ID, { amount: 4000 });

      expect(mockPrisma.budget.update).toHaveBeenCalled();
    });

    it('kullanıcıya ait değilse NotFoundException fırlatır', async () => {
      mockPrisma.budget.findFirst.mockResolvedValue(null);

      await expect(service.update(USER_ID, 'other-budget', {})).rejects.toThrow(
        NotFoundException,
      );
    });

    it('arşivlenmiş bütçeye PATCH → 400 BadRequestException', async () => {
      mockPrisma.budget.findFirst.mockResolvedValue({
        ...baseBudget,
        isActive: false,
      });

      await expect(
        service.update(USER_ID, BUDGET_ID, { amount: 4000 }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // ─── remove ──────────────────────────────────────────────────────────────────

  describe('remove()', () => {
    it('bütçeyi siler', async () => {
      mockPrisma.budget.findFirst.mockResolvedValue(baseBudget);
      mockPrisma.budget.delete.mockResolvedValue(baseBudget);

      const result = await service.remove(USER_ID, BUDGET_ID);

      expect(mockPrisma.budget.delete).toHaveBeenCalledWith({
        where: { id: BUDGET_ID },
      });
    });

    it('bulunamazsa NotFoundException fırlatır', async () => {
      mockPrisma.budget.findFirst.mockResolvedValue(null);

      await expect(service.remove(USER_ID, 'nonexistent')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  // ─── archiveExpired ───────────────────────────────────────────────────────────

  describe('archiveExpired()', () => {
    it('boş liste ile 0 işler', async () => {
      mockPrisma.budget.findMany.mockResolvedValue([]);
      mockPrisma.sharedBudget.findMany.mockResolvedValue([]);

      const result = await service.archiveExpired();

      expect(result).toEqual({ personal: 0, shared: 0 });
      expect(mockPrisma.budget.update).not.toHaveBeenCalled();
      expect(mockPrisma.sharedBudget.update).not.toHaveBeenCalled();
    });

    it('süresi geçmiş 3 kişisel + 2 ortak bütçeyi arşivler', async () => {
      const expiredPersonal = [
        { ...baseBudget, id: 'b1' },
        { ...baseBudget, id: 'b2' },
        { ...baseBudget, id: 'b3' },
      ];
      const expiredShared = [
        {
          id: 'sb1',
          groupId: 'g1',
          name: 'Ortak Market',
          amount: 5000,
          spent: 3000,
          group: { name: 'Ev', members: [{ userId: 'u1' }, { userId: 'u2' }] },
          category: { name: 'Market' },
        },
        {
          id: 'sb2',
          groupId: 'g1',
          name: 'Ortak Eğlence',
          amount: 2000,
          spent: 2500,
          group: { name: 'Ev', members: [{ userId: 'u1' }] },
          category: { name: 'Eğlence' },
        },
      ];

      mockPrisma.budget.findMany.mockResolvedValue(expiredPersonal);
      mockPrisma.sharedBudget.findMany.mockResolvedValue(expiredShared);
      mockPrisma.budget.update.mockResolvedValue({});
      mockPrisma.sharedBudget.update.mockResolvedValue({});
      mockNotifications.sendToUser.mockResolvedValue(undefined);

      const result = await service.archiveExpired();

      expect(result).toEqual({ personal: 3, shared: 2 });
      expect(mockPrisma.budget.update).toHaveBeenCalledTimes(3);
      expect(mockPrisma.sharedBudget.update).toHaveBeenCalledTimes(2);

      // Tüm bütçelere isActive: false set edildi
      for (const call of mockPrisma.budget.update.mock.calls) {
        expect(call[0].data).toEqual({ isActive: false });
      }
    });

    it('kişisel bildirim aşılmamışta CTA içerir, aşılmışta tutarı ayarla mesajı içerir', async () => {
      const notExceeded = { ...baseBudget, id: 'b1', amount: 5000, spent: 4500 };
      const exceeded = { ...baseBudget, id: 'b2', amount: 5000, spent: 5500 };

      mockPrisma.budget.findMany.mockResolvedValue([notExceeded, exceeded]);
      mockPrisma.sharedBudget.findMany.mockResolvedValue([]);
      mockPrisma.budget.update.mockResolvedValue({});
      mockNotifications.sendToUser.mockResolvedValue(undefined);

      await service.archiveExpired();
      await flushSetImmediate();

      const calls = mockNotifications.sendToUser.mock.calls;
      expect(calls).toHaveLength(2);

      // Aşılmamış — CTA "yenisini oluşturmak"
      const [notExcCall] = calls.find((c) => c[1] === 'Bütçe dönemi kapandı')!;
      const notExcBody = calls.find((c) => c[1] === 'Bütçe dönemi kapandı')![2] as string;
      expect(notExcBody).toContain('yenisini oluşturmak ister misin?');

      // Aşılmış — CTA "tutarı ayarlamak"
      const excBody = calls.find((c) => c[1] === 'Bütçe dönemi kapandı (aşıldı)')![2] as string;
      expect(excBody).toContain('tutarı ayarlamak ister misin?');
    });

    it('ortak bildirim CTA içermez (salt bilgi), tüm üyelere gönderilir', async () => {
      const sharedBudget = {
        id: 'sb1',
        groupId: 'g1',
        name: 'Ortak Market',
        amount: 10000,
        spent: 8200,
        group: {
          name: 'Ev',
          members: [{ userId: 'u1' }, { userId: 'u2' }, { userId: 'u3' }],
        },
        category: { name: 'Market' },
      };

      mockPrisma.budget.findMany.mockResolvedValue([]);
      mockPrisma.sharedBudget.findMany.mockResolvedValue([sharedBudget]);
      mockPrisma.sharedBudget.update.mockResolvedValue({});
      mockNotifications.sendToUser.mockResolvedValue(undefined);

      await service.archiveExpired();
      await flushSetImmediate();

      const calls = mockNotifications.sendToUser.mock.calls;
      // 3 üyeye bildirim
      expect(calls).toHaveLength(3);
      expect(calls.map((c) => c[0])).toEqual(
        expect.arrayContaining(['u1', 'u2', 'u3']),
      );

      // Hiçbirinde prefilled CTA yok
      for (const call of calls) {
        const body = call[2] as string;
        expect(body).not.toContain('yenisini oluşturmak');
        expect(body).not.toContain('tutarı ayarlamak');
      }
    });

    it('kişisel bildirim data payload scope=personal ve closedBudgetId içerir', async () => {
      mockPrisma.budget.findMany.mockResolvedValue([{ ...baseBudget, id: 'b1' }]);
      mockPrisma.sharedBudget.findMany.mockResolvedValue([]);
      mockPrisma.budget.update.mockResolvedValue({});
      mockNotifications.sendToUser.mockResolvedValue(undefined);

      await service.archiveExpired();
      await flushSetImmediate();

      const [, , , data] = mockNotifications.sendToUser.mock.calls[0];
      expect(data).toMatchObject({
        type: 'BUDGET_CLOSED',
        scope: 'personal',
        closedBudgetId: 'b1',
      });
    });

    it('ortak bildirim data payload scope=shared ve closedSharedBudgetId içerir', async () => {
      const sharedBudget = {
        id: 'sb1',
        groupId: 'g1',
        name: 'Ortak',
        amount: 1000,
        spent: 500,
        group: { name: 'Ev', members: [{ userId: 'u1' }] },
        category: { name: 'Market' },
      };

      mockPrisma.budget.findMany.mockResolvedValue([]);
      mockPrisma.sharedBudget.findMany.mockResolvedValue([sharedBudget]);
      mockPrisma.sharedBudget.update.mockResolvedValue({});
      mockNotifications.sendToUser.mockResolvedValue(undefined);

      await service.archiveExpired();
      await flushSetImmediate();

      const [, , , data] = mockNotifications.sendToUser.mock.calls[0];
      expect(data).toMatchObject({
        type: 'BUDGET_CLOSED',
        scope: 'shared',
        closedSharedBudgetId: 'sb1',
        groupId: 'g1',
      });
    });
  });

  // ─── Event Listener'lar ──────────────────────────────────────────────────────

  describe('@OnEvent(transaction.created)', () => {
    it('EXPENSE işlemi oluşturulduğunda etkilenen bütçelerin spent değerini günceller', async () => {
      mockPrisma.budget.findMany.mockResolvedValue([baseBudget]);
      mockPrisma.transaction.aggregate.mockResolvedValue({
        _sum: { amount: 600 },
      });
      mockPrisma.budget.update.mockResolvedValue({ ...baseBudget, spent: 600 });

      const event = new TransactionCreatedEvent(
        'tx-1',
        USER_ID,
        'acc-1',
        CATEGORY_ID,
        TransactionType.EXPENSE,
        TransactionSource.MANUAL,
        100,
        new Date(),
      );

      await service.onTransactionCreated(event);

      expect(mockPrisma.budget.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: { spent: 600 } }),
      );
    });

    it('INCOME işleminde bütçe güncellemesi yapmaz', async () => {
      const event = new TransactionCreatedEvent(
        'tx-2',
        USER_ID,
        'acc-1',
        CATEGORY_ID,
        TransactionType.INCOME,
        TransactionSource.MANUAL,
        5000,
        new Date(),
      );

      await service.onTransactionCreated(event);

      expect(mockPrisma.budget.findMany).not.toHaveBeenCalled();
    });
  });

  describe('@OnEvent(transaction.deleted)', () => {
    it('EXPENSE işlemi silindiğinde spent değerini yeniden hesaplar', async () => {
      mockPrisma.budget.findMany.mockResolvedValue([baseBudget]);
      mockPrisma.transaction.aggregate.mockResolvedValue({
        _sum: { amount: 400 },
      });
      mockPrisma.budget.update.mockResolvedValue({ ...baseBudget, spent: 400 });

      const event = new TransactionDeletedEvent(
        'tx-1',
        USER_ID,
        CATEGORY_ID,
        TransactionType.EXPENSE,
        100,
        new Date(),
      );

      await service.onTransactionDeleted(event);

      expect(mockPrisma.budget.update).toHaveBeenCalled();
    });
  });

  describe('@OnEvent(transaction.updated)', () => {
    it('EXPENSE güncelleme sonrası ilgili bütçeleri yeniden hesaplar', async () => {
      mockPrisma.budget.findMany.mockResolvedValue([baseBudget]);
      mockPrisma.transaction.aggregate.mockResolvedValue({
        _sum: { amount: 700 },
      });
      mockPrisma.budget.update.mockResolvedValue({ ...baseBudget, spent: 700 });

      const event = new TransactionUpdatedEvent(
        'tx-1',
        USER_ID,
        CATEGORY_ID,
        CATEGORY_ID,
        TransactionType.EXPENSE,
        TransactionType.EXPENSE,
        100,
        150,
        new Date(),
      );

      await service.onTransactionUpdated(event);

      expect(mockPrisma.budget.update).toHaveBeenCalled();
    });
  });

  // ─── Enflasyon Önerisi ────────────────────────────────────────────────────────

  describe('getInflationSuggestion()', () => {
    const budgetUpdatedAt = new Date('2026-02-01T00:00:00Z');
    const budgetWithUpdatedAt = {
      ...baseBudget,
      updatedAt: budgetUpdatedAt,
    };

    it('kategori inflation map yoksa 422 fırlatır', async () => {
      mockPrisma.budget.findFirst.mockResolvedValue(budgetWithUpdatedAt);
      mockPrisma.categoryInflationMap.findUnique.mockResolvedValue(null);

      await expect(
        service.getInflationSuggestion(USER_ID, BUDGET_ID),
      ).rejects.toThrow(UnprocessableEntityException);
    });

    it('anlamlılık eşiğinin altındaysa null döner (204)', async () => {
      mockPrisma.budget.findFirst.mockResolvedValue({
        ...budgetWithUpdatedAt,
        amount: 3000,
        updatedAt: new Date(), // az önce güncellendi → 0 ay geçmiş
      });
      mockPrisma.categoryInflationMap.findUnique.mockResolvedValue({
        categoryId: CATEGORY_ID,
        inflationKey: 'gida',
      });
      // Veri yok → kümülatif rate = 0
      mockPrisma.inflationRate.findMany.mockResolvedValue([]);

      const result = await service.getInflationSuggestion(USER_ID, BUDGET_ID);

      expect(result).toBeNull();
    });

    it('anlamlı öneri varsa suggestion DTO döner', async () => {
      mockPrisma.budget.findFirst.mockResolvedValue({
        ...budgetWithUpdatedAt,
        amount: 3000,
      });
      mockPrisma.categoryInflationMap.findUnique.mockResolvedValue({
        categoryId: CATEGORY_ID,
        inflationKey: 'gida',
      });
      // 3 ay × %3 → kümülatif ~%9.27, fark ~278 TL
      mockPrisma.inflationRate.findMany.mockResolvedValue([
        { categoryKey: 'gida', year: 2026, month: 3, monthlyRate: 3.0, yearlyRate: 45.0 },
        { categoryKey: 'gida', year: 2026, month: 4, monthlyRate: 3.0, yearlyRate: 45.0 },
        { categoryKey: 'gida', year: 2026, month: 5, monthlyRate: 3.0, yearlyRate: 45.0 },
      ]);

      const result = await service.getInflationSuggestion(USER_ID, BUDGET_ID);

      expect(result).not.toBeNull();
      expect(result!.budgetId).toBe(BUDGET_ID);
      expect(result!.currentAmount).toBe(3000);
      expect(result!.suggestedAmount).toBeGreaterThan(3000);
      expect(result!.cumulativeRate).toBeGreaterThan(5);
      expect(result!.categoryKey).toBe('gida');
    });
  });

  // ─── applyInflation ───────────────────────────────────────────────────────────

  describe('applyInflation()', () => {
    const budgetUpdatedAt = new Date('2026-02-01T00:00:00Z');

    it('öneri yoksa (204 senaryosu) 400 fırlatır', async () => {
      mockPrisma.budget.findFirst.mockResolvedValue({
        ...baseBudget,
        amount: 3000,
        updatedAt: new Date(), // az önce güncellendi
      });
      mockPrisma.categoryInflationMap.findUnique.mockResolvedValue({
        categoryId: CATEGORY_ID,
        inflationKey: 'gida',
      });
      mockPrisma.inflationRate.findMany.mockResolvedValue([]);

      await expect(
        service.applyInflation(USER_ID, BUDGET_ID, { newAmount: 3100 }),
      ).rejects.toThrow(BadRequestException);
    });

    it('newAmount ±%10 dışındaysa 400 fırlatır', async () => {
      mockPrisma.budget.findFirst.mockResolvedValue({
        ...baseBudget,
        amount: 3000,
        updatedAt: budgetUpdatedAt,
      });
      mockPrisma.categoryInflationMap.findUnique.mockResolvedValue({
        categoryId: CATEGORY_ID,
        inflationKey: 'gida',
      });
      mockPrisma.inflationRate.findMany.mockResolvedValue([
        { categoryKey: 'gida', year: 2026, month: 3, monthlyRate: 3.0, yearlyRate: 45.0 },
        { categoryKey: 'gida', year: 2026, month: 4, monthlyRate: 3.0, yearlyRate: 45.0 },
        { categoryKey: 'gida', year: 2026, month: 5, monthlyRate: 3.0, yearlyRate: 45.0 },
      ]);

      // suggestedAmount ~3278, ±%10: 2950 - 3606 aralığı
      // 5000 aralık dışı
      await expect(
        service.applyInflation(USER_ID, BUDGET_ID, { newAmount: 5000 }),
      ).rejects.toThrow(BadRequestException);
    });

    it('geçerli newAmount ile update çağrılır', async () => {
      mockPrisma.budget.findFirst.mockResolvedValue({
        ...baseBudget,
        amount: 3000,
        updatedAt: budgetUpdatedAt,
      });
      mockPrisma.categoryInflationMap.findUnique.mockResolvedValue({
        categoryId: CATEGORY_ID,
        inflationKey: 'gida',
      });
      mockPrisma.inflationRate.findMany.mockResolvedValue([
        { categoryKey: 'gida', year: 2026, month: 3, monthlyRate: 3.0, yearlyRate: 45.0 },
        { categoryKey: 'gida', year: 2026, month: 4, monthlyRate: 3.0, yearlyRate: 45.0 },
        { categoryKey: 'gida', year: 2026, month: 5, monthlyRate: 3.0, yearlyRate: 45.0 },
      ]);
      // findFirst mock'u update için de kullanılıyor (update içinde findOwned)
      mockPrisma.budget.update.mockResolvedValue({ ...baseBudget, amount: 3278 });

      // suggestedAmount ~3278, ±%10: ~2950 - ~3606 → 3278 geçerli
      const result = await service.applyInflation(USER_ID, BUDGET_ID, {
        newAmount: 3278,
      });

      expect(mockPrisma.budget.update).toHaveBeenCalled();
    });
  });
});
