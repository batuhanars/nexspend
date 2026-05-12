/* eslint-disable */
import { NotFoundException } from '@nestjs/common';
import { InsightService } from './insight.service';

const mockPrisma = {
  insight: {
    findMany: jest.fn(),
    count: jest.fn(),
    findFirst: jest.fn(),
    update: jest.fn(),
    create: jest.fn(),
  },
  user: {
    findMany: jest.fn(),
  },
};

const mockRulesService = {
  runAll: jest.fn(),
};

const USER_ID = 'user-1';
const INSIGHT_ID = 'insight-1';
const PERIOD = '2026-04';

const baseInsight = {
  id: INSIGHT_ID,
  userId: USER_ID,
  ruleId: 'spending_spike',
  title: 'Market harcaman bu ay %42 arttı',
  message: 'Geçen 3 ayın ortalaması ₺2.100, bu ay ₺2.982.',
  category: 'Market',
  severity: 'warning',
  data: null,
  isRead: false,
  isDismissed: false,
  period: PERIOD,
  createdAt: new Date('2026-05-01T08:00:00Z'),
};

describe('InsightService', () => {
  let service: InsightService;

  beforeEach(() => {
    service = new InsightService(mockPrisma as any, mockRulesService as any);
    jest.clearAllMocks();
  });

  // ─── findAll ─────────────────────────────────────────────────────────────────

  describe('findAll()', () => {
    it('sayfalanmış insight listesini döner', async () => {
      mockPrisma.insight.findMany.mockResolvedValue([baseInsight]);
      mockPrisma.insight.count.mockResolvedValue(1);

      const result = await service.findAll(USER_ID, { period: PERIOD });

      expect(result.items).toHaveLength(1);
      expect(result.total).toBe(1);
      expect(result.page).toBe(1);
      expect(result.limit).toBe(20);
    });

    it('unread=true filtresi uygulanır', async () => {
      mockPrisma.insight.findMany.mockResolvedValue([]);
      mockPrisma.insight.count.mockResolvedValue(0);

      await service.findAll(USER_ID, { period: PERIOD, unread: true });

      expect(mockPrisma.insight.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ isRead: false }),
        }),
      );
    });
  });

  // ─── findSummary ─────────────────────────────────────────────────────────────

  describe('findSummary()', () => {
    it('unreadCount, totalCount ve latestInsight döner', async () => {
      mockPrisma.insight.count
        .mockResolvedValueOnce(2) // unreadCount
        .mockResolvedValueOnce(5); // totalCount
      mockPrisma.insight.findFirst.mockResolvedValue(baseInsight);

      const result = await service.findSummary(USER_ID);

      expect(result.unreadCount).toBe(2);
      expect(result.totalCount).toBe(5);
      expect(result.latestInsight).not.toBeNull();
      expect(result.latestInsight!.id).toBe(INSIGHT_ID);
    });

    it('insight yoksa latestInsight null döner', async () => {
      mockPrisma.insight.count.mockResolvedValue(0);
      mockPrisma.insight.findFirst.mockResolvedValue(null);

      const result = await service.findSummary(USER_ID);

      expect(result.latestInsight).toBeNull();
    });
  });

  // ─── markRead ────────────────────────────────────────────────────────────────

  describe('markRead()', () => {
    it('isRead true olarak güncellenir', async () => {
      mockPrisma.insight.findFirst.mockResolvedValue(baseInsight);
      mockPrisma.insight.update.mockResolvedValue({ ...baseInsight, isRead: true });

      const result = await service.markRead(USER_ID, INSIGHT_ID);

      expect(mockPrisma.insight.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: { isRead: true } }),
      );
      expect(result.isRead).toBe(true);
    });

    it('insight kullanıcıya ait değilse NotFoundException', async () => {
      mockPrisma.insight.findFirst.mockResolvedValue(null);

      await expect(service.markRead(USER_ID, 'other-id')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  // ─── dismiss ─────────────────────────────────────────────────────────────────

  describe('dismiss()', () => {
    it('isDismissed true olarak güncellenir', async () => {
      mockPrisma.insight.findFirst.mockResolvedValue(baseInsight);
      mockPrisma.insight.update.mockResolvedValue({ ...baseInsight, isDismissed: true });

      const result = await service.dismiss(USER_ID, INSIGHT_ID);

      expect(mockPrisma.insight.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: { isDismissed: true } }),
      );
      expect(result.isDismissed).toBe(true);
    });

    it('insight kullanıcıya ait değilse NotFoundException', async () => {
      mockPrisma.insight.findFirst.mockResolvedValue(null);

      await expect(service.dismiss(USER_ID, 'other-id')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  // ─── generate ────────────────────────────────────────────────────────────────

  describe('generate()', () => {
    it('kurallar çalışır ve upsert yapılır', async () => {
      mockRulesService.runAll.mockResolvedValue([
        {
          ruleId: 'spending_spike',
          title: 'Market artı',
          message: 'Detay',
          category: 'Market',
        },
      ]);
      mockPrisma.insight.findFirst.mockResolvedValue(null); // yeni kayıt
      mockPrisma.insight.create.mockResolvedValue(baseInsight);

      const result = await service.generate(USER_ID, PERIOD);

      expect(result.generated).toBe(1);
      expect(result.period).toBe(PERIOD);
      expect(mockPrisma.insight.create).toHaveBeenCalledTimes(1);
    });

    it('mevcut insight varsa update yapılır', async () => {
      mockRulesService.runAll.mockResolvedValue([
        { ruleId: 'spending_spike', title: 'Güncel', message: 'Güncel mesaj' },
      ]);
      mockPrisma.insight.findFirst.mockResolvedValue(baseInsight); // mevcut var
      mockPrisma.insight.update.mockResolvedValue({ ...baseInsight, title: 'Güncel' });

      const result = await service.generate(USER_ID, PERIOD);

      expect(result.generated).toBe(1);
      expect(mockPrisma.insight.update).toHaveBeenCalledTimes(1);
      expect(mockPrisma.insight.create).not.toHaveBeenCalled();
    });
  });
});
