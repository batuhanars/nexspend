import { Test, TestingModule } from '@nestjs/testing';
import { ReportsService } from './reports.service';
import { PrismaService } from '../../prisma/prisma.service';
import { ReportPeriod } from './dto/query-report.dto';

describe('ReportsService', () => {
  let service: ReportsService;
  const mockPrisma = {
    transaction: { groupBy: jest.fn() },
    category: { findMany: jest.fn() },
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ReportsService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();
    service = module.get<ReportsService>(ReportsService);
  });

  describe('getTrends', () => {
    it('kategori bazında bu dönem vs önceki dönem değişimini hesaplar', async () => {
      // groupExpenseByCategory iki kez çağrılır: önce cari, sonra önceki dönem.
      mockPrisma.transaction.groupBy
        .mockResolvedValueOnce([
          { categoryId: 'a', _sum: { amount: 300 } }, // cari: Market
          { categoryId: 'b', _sum: { amount: 100 } }, // cari: Ulaşım (yeni)
        ])
        .mockResolvedValueOnce([
          { categoryId: 'a', _sum: { amount: 200 } }, // önceki: Market
          { categoryId: 'c', _sum: { amount: 50 } }, // önceki: Eğlence (kesildi)
        ]);
      mockPrisma.category.findMany.mockResolvedValue([
        { id: 'a', name: 'Market' },
        { id: 'b', name: 'Ulaşım' },
        { id: 'c', name: 'Eğlence' },
      ]);

      const result = await service.getTrends('user-1', {
        period: ReportPeriod.THIS_MONTH,
      });

      // En çok harcanan başta: Market(300) → Ulaşım(100) → Eğlence(0)
      expect(result.map((r) => r.categoryName)).toEqual([
        'Market',
        'Ulaşım',
        'Eğlence',
      ]);

      const market = result.find((r) => r.categoryName === 'Market')!;
      expect(market.currentAmount).toBe(300);
      expect(market.previousAmount).toBe(200);
      expect(market.changePercent).toBe(50); // (300-200)/200 = +%50

      const ulasim = result.find((r) => r.categoryName === 'Ulaşım')!;
      expect(ulasim.previousAmount).toBe(0);
      expect(ulasim.changePercent).toBe(100); // önceki yok → +%100

      const eglence = result.find((r) => r.categoryName === 'Eğlence')!;
      expect(eglence.currentAmount).toBe(0);
      expect(eglence.changePercent).toBe(-100); // tamamen kesilmiş → -%100
    });

    it('hiç işlem yoksa boş liste döner (hata fırlatmaz)', async () => {
      mockPrisma.transaction.groupBy
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([]);
      mockPrisma.category.findMany.mockResolvedValue([]);

      const result = await service.getTrends('user-1', {
        period: ReportPeriod.THIS_MONTH,
      });

      expect(result).toEqual([]);
    });
  });
});
