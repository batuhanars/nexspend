import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { Insight } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { INSIGHT_SEVERITY_MAP } from './insight.constants';
import { InsightRulesService } from './insight-rules.service';
import { InsightDto } from './dto/insight.dto';
import { InsightQueryDto } from './dto/insight-query.dto';

@Injectable()
export class InsightService {
  private readonly logger = new Logger(InsightService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly rulesService: InsightRulesService,
  ) {}

  async findAll(userId: string, query: InsightQueryDto) {
    const period = query.period ?? this.currentPeriod();
    const page = query.page ?? 1;
    const limit = Math.min(query.limit ?? 20, 100);
    const skip = (page - 1) * limit;

    const where = {
      userId,
      period,
      isDismissed: false,
      ...(query.unread === true && { isRead: false }),
    };

    const [items, total] = await Promise.all([
      this.prisma.insight.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.insight.count({ where }),
    ]);

    return { items: items.map((i) => this.toDto(i)), total, page, limit };
  }

  async findSummary(userId: string) {
    const period = this.currentPeriod();

    const [unreadCount, totalCount, latestInsight] = await Promise.all([
      this.prisma.insight.count({
        where: { userId, period, isDismissed: false, isRead: false },
      }),
      this.prisma.insight.count({
        where: { userId, period, isDismissed: false },
      }),
      this.prisma.insight.findFirst({
        where: { userId, isDismissed: false },
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    return {
      unreadCount,
      totalCount,
      latestInsight: latestInsight ? this.toDto(latestInsight) : null,
    };
  }

  async markRead(userId: string, id: string): Promise<InsightDto> {
    await this.findOwned(userId, id);
    const updated = await this.prisma.insight.update({
      where: { id },
      data: { isRead: true },
    });
    return this.toDto(updated);
  }

  async dismiss(userId: string, id: string): Promise<InsightDto> {
    await this.findOwned(userId, id);
    const updated = await this.prisma.insight.update({
      where: { id },
      data: { isDismissed: true },
    });
    return this.toDto(updated);
  }

  async generate(
    userId: string,
    period?: string,
  ): Promise<{ generated: number; period: string }> {
    const targetPeriod = period ?? this.currentPeriod();
    const results = await this.rulesService.runAll(userId, targetPeriod);

    let count = 0;
    for (const result of results) {
      const severity = INSIGHT_SEVERITY_MAP[result.ruleId];
      const existing = await this.prisma.insight.findFirst({
        where: { userId, ruleId: result.ruleId, period: targetPeriod },
      });

      if (existing) {
        await this.prisma.insight.update({
          where: { id: existing.id },
          data: {
            title: result.title,
            message: result.message,
            category: result.category ?? null,
            severity,
            isRead: false,
          },
        });
      } else {
        await this.prisma.insight.create({
          data: {
            userId,
            ruleId: result.ruleId,
            title: result.title,
            message: result.message,
            category: result.category ?? null,
            severity,
            data: null,
            isRead: false,
            isDismissed: false,
            period: targetPeriod,
          },
        });
      }
      count++;
    }

    this.logger.log(
      `${userId} için ${count} insight oluşturuldu (${targetPeriod})`,
    );
    return { generated: count, period: targetPeriod };
  }

  async generateForAllUsers(period: string): Promise<void> {
    const users = await this.prisma.user.findMany({ select: { id: true } });
    for (const user of users) {
      try {
        await this.generate(user.id, period);
      } catch (err) {
        this.logger.error(
          `${user.id} için insight üretilemedi: ${(err as Error).message}`,
        );
      }
    }
  }

  // ─── Private Helpers ─────────────────────────────────────────────────────────

  private async findOwned(userId: string, id: string) {
    const insight = await this.prisma.insight.findFirst({
      where: { id, userId },
    });
    if (!insight) throw new NotFoundException('Insight bulunamadı');
    return insight;
  }

  private toDto(insight: Insight): InsightDto {
    return {
      id: insight.id,
      ruleId: insight.ruleId,
      title: insight.title,
      message: insight.message,
      category: insight.category,
      severity: insight.severity as 'info' | 'warning' | 'success',
      data: insight.data ? (JSON.parse(insight.data) as unknown) : null,
      isRead: insight.isRead,
      isDismissed: insight.isDismissed,
      period: insight.period,
      createdAt: insight.createdAt.toISOString(),
    };
  }

  private currentPeriod(): string {
    const now = new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  }
}
