/* eslint-disable */
import { InsightRulesService } from './insight-rules.service';

const mockPrisma = {
  transaction: {
    groupBy: jest.fn(),
    aggregate: jest.fn(),
    findMany: jest.fn(),
    count: jest.fn(),
  },
  category: {
    findUnique: jest.fn(),
  },
  subscription: {
    findMany: jest.fn(),
  },
  budget: {
    findMany: jest.fn(),
  },
  debt: {
    findFirst: jest.fn(),
  },
  inflationRate: {
    count: jest.fn(),
    findUnique: jest.fn(),
  },
  categoryInflationMap: {
    findUnique: jest.fn(),
  },
};

const USER_ID = 'user-1';
const PERIOD = '2026-04';
const CAT_ID = 'cat-1';

describe('InsightRulesService', () => {
  let service: InsightRulesService;

  beforeEach(() => {
    service = new InsightRulesService(mockPrisma as any);
    jest.clearAllMocks();
  });

  // ─── spending_spike ───────────────────────────────────────────────────────────

  describe('checkSpendingSpike()', () => {
    it('triggered: %30+ artış varsa insight döner', async () => {
      // current: 3000, prev 3 months total: 3000 → avg 1000 → %200 artış
      mockPrisma.transaction.groupBy
        .mockResolvedValueOnce([{ categoryId: CAT_ID, _sum: { amount: 3000 } }])
        .mockResolvedValueOnce([{ categoryId: CAT_ID, _sum: { amount: 3000 } }]);
      mockPrisma.category.findUnique.mockResolvedValue({ name: 'Market' });

      const result = await service.checkSpendingSpike(USER_ID, PERIOD);

      expect(result).not.toBeNull();
      expect(result!.ruleId).toBe('spending_spike');
      expect(result!.category).toBe('Market');
    });

    it('not triggered: artış %30 altında', async () => {
      // current: 1100, prev 3 months total: 3000 → avg 1000 → %10 artış
      mockPrisma.transaction.groupBy
        .mockResolvedValueOnce([{ categoryId: CAT_ID, _sum: { amount: 1100 } }])
        .mockResolvedValueOnce([{ categoryId: CAT_ID, _sum: { amount: 3000 } }]);

      const result = await service.checkSpendingSpike(USER_ID, PERIOD);

      expect(result).toBeNull();
    });
  });

  // ─── unused_subscription ─────────────────────────────────────────────────────

  describe('checkUnusedSubscription()', () => {
    it('triggered: kategoride son 60 günde 0 işlem', async () => {
      mockPrisma.subscription.findMany.mockResolvedValue([
        {
          id: 'sub-1',
          name: 'Spotify',
          amount: 59.99,
          period: 'MONTHLY',
          categoryId: CAT_ID,
          isActive: true,
          category: { name: 'Eğlence' },
        },
      ]);
      mockPrisma.transaction.count.mockResolvedValue(0);

      const result = await service.checkUnusedSubscription(USER_ID);

      expect(result).not.toBeNull();
      expect(result!.ruleId).toBe('unused_subscription');
    });

    it('not triggered: kategoride işlem var', async () => {
      mockPrisma.subscription.findMany.mockResolvedValue([
        {
          id: 'sub-1',
          name: 'Spotify',
          amount: 59.99,
          period: 'MONTHLY',
          categoryId: CAT_ID,
          isActive: true,
          category: { name: 'Eğlence' },
        },
      ]);
      mockPrisma.transaction.count.mockResolvedValue(3);

      const result = await service.checkUnusedSubscription(USER_ID);

      expect(result).toBeNull();
    });
  });

  // ─── category_overrun ─────────────────────────────────────────────────────────

  describe('checkCategoryOverrun()', () => {
    const baseBudget = {
      id: 'bud-1',
      categoryId: CAT_ID,
      name: 'Market Bütçesi',
      amount: 1000,
      period: 'MONTHLY',
      isActive: true,
      startDate: new Date('2026-01-01'),
      endDate: null,
      category: { name: 'Market' },
    };

    it('triggered: ilk 15 günde bütçenin %70+ tüketildi', async () => {
      mockPrisma.budget.findMany.mockResolvedValue([baseBudget]);
      mockPrisma.transaction.aggregate.mockResolvedValue({
        _sum: { amount: 750 }, // 750/1000 = 75% ≥ 70%
      });

      const result = await service.checkCategoryOverrun(USER_ID, PERIOD);

      expect(result).not.toBeNull();
      expect(result!.ruleId).toBe('category_overrun');
      expect(result!.category).toBe('Market');
    });

    it('not triggered: ilk 15 günde bütçenin %70 altında tüketildi', async () => {
      mockPrisma.budget.findMany.mockResolvedValue([baseBudget]);
      mockPrisma.transaction.aggregate.mockResolvedValue({
        _sum: { amount: 400 }, // 400/1000 = 40% < 70%
      });

      const result = await service.checkCategoryOverrun(USER_ID, PERIOD);

      expect(result).toBeNull();
    });
  });

  // ─── recurring_drift ─────────────────────────────────────────────────────────

  describe('checkRecurringDrift()', () => {
    it('triggered: tekrarlayan işlem tutarı %20+ değişti', async () => {
      const now = new Date('2026-04-15');
      mockPrisma.transaction.findMany.mockResolvedValue([
        { title: 'Elektrik', amount: 300, transactionDate: new Date('2026-02-10') },
        { title: 'Elektrik', amount: 380, transactionDate: new Date('2026-03-10') },
        { title: 'Elektrik', amount: 440, transactionDate: new Date('2026-04-10') },
      ]);

      const result = await service.checkRecurringDrift(USER_ID, PERIOD);

      expect(result).not.toBeNull();
      expect(result!.ruleId).toBe('recurring_drift');
    });

    it('not triggered: tutarlar sabit', async () => {
      mockPrisma.transaction.findMany.mockResolvedValue([
        { title: 'Elektrik', amount: 300, transactionDate: new Date('2026-02-10') },
        { title: 'Elektrik', amount: 305, transactionDate: new Date('2026-03-10') },
        { title: 'Elektrik', amount: 302, transactionDate: new Date('2026-04-10') },
      ]);

      const result = await service.checkRecurringDrift(USER_ID, PERIOD);

      expect(result).toBeNull();
    });
  });

  // ─── debt_aging ──────────────────────────────────────────────────────────────

  describe('checkDebtAging()', () => {
    it('triggered: 30+ gün önce verilen alacak tahsil edilmedi', async () => {
      const oldDate = new Date();
      oldDate.setDate(oldDate.getDate() - 45);

      mockPrisma.debt.findFirst.mockResolvedValue({
        id: 'debt-1',
        personName: 'Ahmet',
        totalAmount: 500,
        paidAmount: 0,
        createdAt: oldDate,
      });

      const result = await service.checkDebtAging(USER_ID);

      expect(result).not.toBeNull();
      expect(result!.ruleId).toBe('debt_aging');
    });

    it('not triggered: eski alacak yok', async () => {
      mockPrisma.debt.findFirst.mockResolvedValue(null);

      const result = await service.checkDebtAging(USER_ID);

      expect(result).toBeNull();
    });
  });

  // ─── inflation_gap ────────────────────────────────────────────────────────────

  describe('checkInflationGap()', () => {
    it('skip: inflation tablosu boş', async () => {
      mockPrisma.inflationRate.count.mockResolvedValue(0);

      const result = await service.checkInflationGap(USER_ID, PERIOD);

      expect(result).toBeNull();
    });

    it('triggered: kategori harcaması enflasyonun %5 üstünde', async () => {
      mockPrisma.inflationRate.count.mockResolvedValue(10);
      // current: 1200, prev: 1000 → %20 artış. inflation: 3%. excess: 20-3=17% > 5% → trigger
      mockPrisma.transaction.groupBy
        .mockResolvedValueOnce([{ categoryId: CAT_ID, _sum: { amount: 1200 } }])
        .mockResolvedValueOnce([{ categoryId: CAT_ID, _sum: { amount: 1000 } }]);
      mockPrisma.categoryInflationMap.findUnique.mockResolvedValue({
        categoryId: CAT_ID,
        inflationKey: 'gida',
      });
      mockPrisma.inflationRate.findUnique.mockResolvedValue({
        categoryKey: 'gida',
        year: 2026,
        month: 4,
        monthlyRate: 3.0,
      });
      mockPrisma.category.findUnique.mockResolvedValue({ name: 'Market' });

      const result = await service.checkInflationGap(USER_ID, PERIOD);

      expect(result).not.toBeNull();
      expect(result!.ruleId).toBe('inflation_gap');
    });

    it('not triggered: artış enflasyonun %5 içinde', async () => {
      mockPrisma.inflationRate.count.mockResolvedValue(10);
      // current: 1040, prev: 1000 → %4 artış. inflation: 3%. excess: 4-3=1% ≤ 5% → no trigger
      mockPrisma.transaction.groupBy
        .mockResolvedValueOnce([{ categoryId: CAT_ID, _sum: { amount: 1040 } }])
        .mockResolvedValueOnce([{ categoryId: CAT_ID, _sum: { amount: 1000 } }]);
      mockPrisma.categoryInflationMap.findUnique.mockResolvedValue({
        categoryId: CAT_ID,
        inflationKey: 'gida',
      });
      mockPrisma.inflationRate.findUnique.mockResolvedValue({
        categoryKey: 'gida',
        year: 2026,
        month: 4,
        monthlyRate: 3.0,
      });

      const result = await service.checkInflationGap(USER_ID, PERIOD);

      expect(result).toBeNull();
    });
  });

  // ─── saving_streak ────────────────────────────────────────────────────────────

  describe('checkSavingStreak()', () => {
    it('triggered: 3 ay üst üste pozitif net akış', async () => {
      // 3 ay × 2 aggregate çağrısı = 6 çağrı: income/expense her ay
      mockPrisma.transaction.aggregate
        .mockResolvedValueOnce({ _sum: { amount: 5000 } }) // M-2 income
        .mockResolvedValueOnce({ _sum: { amount: 3000 } }) // M-2 expense
        .mockResolvedValueOnce({ _sum: { amount: 5000 } }) // M-1 income
        .mockResolvedValueOnce({ _sum: { amount: 3000 } }) // M-1 expense
        .mockResolvedValueOnce({ _sum: { amount: 5000 } }) // M income
        .mockResolvedValueOnce({ _sum: { amount: 3000 } }); // M expense

      const result = await service.checkSavingStreak(USER_ID, PERIOD);

      expect(result).not.toBeNull();
      expect(result!.ruleId).toBe('saving_streak');
    });

    it('not triggered: bir ayda negatif net akış', async () => {
      mockPrisma.transaction.aggregate
        .mockResolvedValueOnce({ _sum: { amount: 5000 } }) // M-2 income
        .mockResolvedValueOnce({ _sum: { amount: 3000 } }) // M-2 expense
        .mockResolvedValueOnce({ _sum: { amount: 2000 } }) // M-1 income (negatif)
        .mockResolvedValueOnce({ _sum: { amount: 3000 } }); // M-1 expense

      const result = await service.checkSavingStreak(USER_ID, PERIOD);

      expect(result).toBeNull();
    });
  });

  // ─── runAll ──────────────────────────────────────────────────────────────────

  describe('runAll()', () => {
    it('bir kural hata verince diğerleri devam eder', async () => {
      // spending_spike hata atacak
      mockPrisma.transaction.groupBy.mockRejectedValueOnce(new Error('DB hatası'));
      // Diğer kurallar boş dönecek
      mockPrisma.subscription.findMany.mockResolvedValue([]);
      mockPrisma.budget.findMany.mockResolvedValue([]);
      mockPrisma.transaction.findMany.mockResolvedValue([]);
      mockPrisma.debt.findFirst.mockResolvedValue(null);
      mockPrisma.inflationRate.count.mockResolvedValue(0);
      mockPrisma.transaction.aggregate.mockResolvedValue({ _sum: { amount: 0 } });

      const results = await service.runAll(USER_ID, PERIOD);

      // Hata loglanır, diğerleri çalışır, sonuç listesi döner (boş olabilir)
      expect(Array.isArray(results)).toBe(true);
    });
  });
});
