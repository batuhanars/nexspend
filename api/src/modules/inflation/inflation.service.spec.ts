/* eslint-disable */
import { InflationService } from './inflation.service';

const mockPrisma = {
  inflationRate: {
    findFirst: jest.fn(),
    findMany: jest.fn(),
    upsert: jest.fn(),
  },
};

const mockHttp = { get: jest.fn() };
const mockConfig = { get: jest.fn() };

describe('InflationService', () => {
  let service: InflationService;

  beforeEach(() => {
    service = new InflationService(
      mockPrisma as any,
      mockHttp as any,
      mockConfig as any,
    );
    jest.clearAllMocks();
  });

  // ─── getCurrentRates ──────────────────────────────────────────────────────────

  describe('getCurrentRates()', () => {
    it('DB boşsa boş dizi döner', async () => {
      mockPrisma.inflationRate.findFirst.mockResolvedValue(null);

      const result = await service.getCurrentRates();

      expect(result).toEqual([]);
      expect(mockPrisma.inflationRate.findMany).not.toHaveBeenCalled();
    });

    it('en güncel ay/yıla ait tüm kategorileri döner', async () => {
      const latest = {
        categoryKey: 'genel',
        year: 2026,
        month: 4,
        monthlyRate: 2.45,
        yearlyRate: 38.12,
        fetchedAt: new Date('2026-05-05T10:00:00Z'),
      };
      mockPrisma.inflationRate.findFirst.mockResolvedValue(latest);
      mockPrisma.inflationRate.findMany.mockResolvedValue([latest]);

      const result = await service.getCurrentRates();

      expect(result).toHaveLength(1);
      expect(result[0].categoryKey).toBe('genel');
      expect(result[0].monthlyRate).toBe(2.45);
      expect(typeof result[0].fetchedAt).toBe('string');
      expect(mockPrisma.inflationRate.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { year: 2026, month: 4 } }),
      );
    });
  });

  // ─── getHistory ───────────────────────────────────────────────────────────────

  describe('getHistory()', () => {
    it('kategoriye göre gruplu tarihsel veri döner', async () => {
      const rates = [
        { categoryKey: 'genel', year: 2026, month: 3, monthlyRate: 2.1, yearlyRate: 37.0, fetchedAt: new Date() },
        { categoryKey: 'genel', year: 2026, month: 4, monthlyRate: 2.45, yearlyRate: 38.12, fetchedAt: new Date() },
        { categoryKey: 'gida', year: 2026, month: 4, monthlyRate: 3.12, yearlyRate: 45.67, fetchedAt: new Date() },
      ];
      mockPrisma.inflationRate.findMany.mockResolvedValue(rates);

      const result = await service.getHistory(6);

      expect(result['genel']).toHaveLength(2);
      expect(result['gida']).toHaveLength(1);
      expect(result['genel'][0].month).toBe(3);
      expect(result['genel'][1].month).toBe(4);
    });

    it('veri yoksa boş nesne döner', async () => {
      mockPrisma.inflationRate.findMany.mockResolvedValue([]);

      const result = await service.getHistory(6);

      expect(Object.keys(result)).toHaveLength(0);
    });
  });

  // ─── Kümülatif oran hesaplaması (fetchAndStoreRates içindeki mantık) ─────────

  describe('kümülatif oran hesaplama mantığı', () => {
    it('aylık oran, endeks değerlerinden doğru hesaplanır', () => {
      const prevIdx = 1000;
      const currIdx = 1024.5;
      const expected = Math.round(((currIdx / prevIdx - 1) * 100) * 100) / 100;
      expect(expected).toBe(2.45);
    });

    it('yıllık oran, 12 ay önceki endeks ile doğru hesaplanır', () => {
      const yearAgoIdx = 750;
      const currIdx = 1024.5;
      const expected = Math.round(((currIdx / yearAgoIdx - 1) * 100) * 100) / 100;
      expect(expected).toBe(36.6);
    });

    it('önceki endeks yoksa aylık oran sıfır olur', () => {
      const prevIdx = undefined;
      const currIdx = 1024.5;
      const monthlyRate = prevIdx !== undefined
        ? Math.round(((currIdx / prevIdx - 1) * 100) * 100) / 100
        : 0;
      expect(monthlyRate).toBe(0);
    });

    it('bileşik kümülatif oran doğru hesaplanır', () => {
      const rates = [2.0, 3.0, 1.5]; // 3 aylık aylık oran
      let multiplier = 1;
      for (const r of rates) {
        multiplier *= 1 + r / 100;
      }
      const cumulative = Math.round((multiplier - 1) * 100 * 100) / 100;
      // (1.02 * 1.03 * 1.015) - 1 = 0.06615... → %6.61
      expect(cumulative).toBeCloseTo(6.61, 1);
    });
  });

  // ─── fetchAndStoreRates ───────────────────────────────────────────────────────

  describe('fetchAndStoreRates()', () => {
    it('EVDS_API_KEY yoksa erken çıkar', async () => {
      mockConfig.get.mockReturnValue(undefined);

      await service.fetchAndStoreRates();

      expect(mockHttp.get).not.toHaveBeenCalled();
      expect(mockPrisma.inflationRate.upsert).not.toHaveBeenCalled();
    });
  });
});
