import {
  Injectable,
  NotFoundException,
  ConflictException,
  UnprocessableEntityException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { TransactionType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import {
  TransactionCreatedEvent,
  TransactionUpdatedEvent,
  TransactionDeletedEvent,
} from '../../common/events/transaction.events';
import { CreateBudgetDto } from './dto/create-budget.dto';
import { UpdateBudgetDto } from './dto/update-budget.dto';
import { ApplyInflationDto } from './dto/apply-inflation.dto';
import { NotificationsService } from '../notifications/notifications.service';
import { computeEndDate, parseLocalDate } from './period.utils';

function startOfDayUtc(date: Date): Date {
  const d = new Date(date);
  d.setUTCHours(0, 0, 0, 0);
  return d;
}

@Injectable()
export class BudgetsService {
  private readonly logger = new Logger(BudgetsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

  async findAll(userId: string, includeArchived = false) {
    const budgets = await this.prisma.budget.findMany({
      where: {
        userId,
        ...(includeArchived ? {} : { isActive: true }),
      },
      include: { category: true },
      orderBy: { createdAt: 'desc' },
    });
    return budgets.map((b) => this.format(b));
  }

  async getOverview(userId: string) {
    const budgets = await this.prisma.budget.findMany({
      where: { userId, isActive: true },
    });

    const totalBudget = budgets.reduce((s, b) => s + Number(b.amount), 0);
    const totalSpent = budgets.reduce((s, b) => s + Number(b.spent), 0);
    const percentage =
      totalBudget > 0 ? Math.round((totalSpent / totalBudget) * 100) : 0;

    return {
      totalBudget,
      totalSpent,
      remaining: totalBudget - totalSpent,
      percentage,
      count: budgets.length,
    };
  }

  async findOne(userId: string, id: string) {
    return this.format(await this.findOwned(userId, id));
  }

  async getHistory(userId: string, id: string) {
    const budget = await this.findOwned(userId, id);

    const history = await this.prisma.budget.findMany({
      where: {
        userId,
        categoryId: budget.categoryId,
        endDate: { lt: budget.startDate },
      },
      include: { category: true },
      orderBy: { endDate: 'desc' },
      take: 12,
    });

    return history.map((b) => this.format(b));
  }

  async create(userId: string, dto: CreateBudgetDto) {
    const period = dto.period ?? 'MONTHLY';
    const startDate = parseLocalDate(dto.startDate);
    const endDate = dto.endDate
      ? parseLocalDate(dto.endDate)
      : computeEndDate(startDate, period);

    const existing = await this.prisma.budget.findFirst({
      where: {
        userId,
        categoryId: dto.categoryId,
        isActive: true,
        startDate: { lte: startDate },
        endDate: { gte: startDate },
      },
    });
    if (existing) {
      throw new ConflictException('Bu kategori için zaten aktif bir bütçe var');
    }

    const budget = await this.prisma.budget.create({
      data: {
        userId,
        categoryId: dto.categoryId,
        name: dto.name,
        amount: dto.amount,
        period,
        note: dto.note ?? null,
        smartTracking: dto.smartTracking ?? true,
        startDate,
        endDate,
      },
      include: { category: true },
    });

    const spent = await this.calcSpent(
      userId,
      budget.categoryId,
      budget.startDate,
      budget.endDate,
    );
    const updated = await this.prisma.budget.update({
      where: { id: budget.id },
      data: { spent },
      include: { category: true },
    });

    return this.format(updated);
  }

  async update(userId: string, id: string, dto: UpdateBudgetDto) {
    const budget = await this.findOwned(userId, id);

    if (!budget.isActive) {
      throw new BadRequestException('Geçmiş döneme ait bütçe düzenlenemez');
    }

    const updated = await this.prisma.budget.update({
      where: { id },
      data: {
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.amount !== undefined && { amount: dto.amount }),
        ...(dto.period !== undefined && { period: dto.period }),
        ...(dto.note !== undefined && { note: dto.note }),
        ...(dto.smartTracking !== undefined && {
          smartTracking: dto.smartTracking,
        }),
        ...(dto.isActive !== undefined && { isActive: dto.isActive }),
        ...(dto.endDate !== undefined && {
          endDate: parseLocalDate(dto.endDate),
        }),
      },
      include: { category: true },
    });

    return this.format(updated);
  }

  async remove(userId: string, id: string) {
    await this.findOwned(userId, id);
    await this.prisma.budget.delete({ where: { id } });
    return { message: 'Bütçe silindi' };
  }

  // =============================================
  // Arşivleme
  // =============================================

  async archiveExpired(): Promise<{ personal: number; shared: number }> {
    const today = startOfDayUtc(new Date());

    const expiredPersonal = await this.prisma.budget.findMany({
      where: { isActive: true, endDate: { lt: today } },
      include: { category: true },
    });
    for (const b of expiredPersonal) {
      await this.prisma.budget.update({
        where: { id: b.id },
        data: { isActive: false },
      });
      setImmediate(
        () =>
          void this.notifyPersonalArchive(b).catch((e) => this.logger.error(e)),
      );
    }

    const expiredShared = await this.prisma.sharedBudget.findMany({
      where: { isActive: true, endDate: { lt: today } },
      include: {
        category: true,
        group: {
          include: { members: { select: { userId: true } } },
        },
      },
    });
    for (const b of expiredShared) {
      await this.prisma.sharedBudget.update({
        where: { id: b.id },
        data: { isActive: false },
      });
      setImmediate(
        () =>
          void this.notifySharedArchive(b).catch((e) => this.logger.error(e)),
      );
    }

    return { personal: expiredPersonal.length, shared: expiredShared.length };
  }

  // =============================================
  // Aktif bütçeleri yeniden hesapla (cron)
  // =============================================

  async recomputeAllActive() {
    const activeBudgets = await this.prisma.budget.findMany({
      where: { isActive: true },
      select: { userId: true, categoryId: true },
      distinct: ['userId', 'categoryId'],
    });

    for (const { userId, categoryId } of activeBudgets) {
      try {
        await this.recalculateForCategory(userId, categoryId);
      } catch (err) {
        this.logger.error(
          `userId=${userId} categoryId=${categoryId} güncellenemedi: ${err}`,
        );
      }
    }
  }

  // =============================================
  // Event Listeners
  // =============================================

  @OnEvent('transaction.created')
  async onTransactionCreated(event: TransactionCreatedEvent) {
    if (event.type !== TransactionType.EXPENSE || !event.categoryId) return;
    // Ortak bütçeye atanmış işlem kişisel bütçeyi etkilemez — gereksiz
    // recalculate + spam bildirimleri (PR #X'ten önce yakalandı).
    if (event.sharedBudgetId) return;
    await this.recalculateForCategory(event.userId, event.categoryId);
  }

  @OnEvent('transaction.deleted')
  async onTransactionDeleted(event: TransactionDeletedEvent) {
    if (event.type !== TransactionType.EXPENSE || !event.categoryId) return;
    if (event.sharedBudgetId) return;
    await this.recalculateForCategory(event.userId, event.categoryId);
  }

  @OnEvent('transaction.updated')
  async onTransactionUpdated(event: TransactionUpdatedEvent) {
    // Kişisele "dokunan" ucu seç: sadece sharedBudgetId NULL olan + EXPENSE +
    // categoryId dolu olan tarafları toplama dahil et.
    const affectsOld =
      event.oldType === TransactionType.EXPENSE &&
      event.oldCategoryId &&
      !event.oldSharedBudgetId;
    const affectsNew =
      event.newType === TransactionType.EXPENSE &&
      event.newCategoryId &&
      !event.newSharedBudgetId;

    if (!affectsOld && !affectsNew) return;

    const categories = new Set<string>();
    if (affectsOld) categories.add(event.oldCategoryId);
    if (affectsNew) categories.add(event.newCategoryId);

    for (const categoryId of categories) {
      await this.recalculateForCategory(event.userId, categoryId);
    }
  }

  // =============================================
  // Helpers
  // =============================================

  async recalculateForCategory(userId: string, categoryId: string) {
    const budgets = await this.prisma.budget.findMany({
      where: { userId, categoryId, isActive: true },
      include: { category: { select: { name: true } } },
    });

    for (const budget of budgets) {
      try {
        const spent = await this.calcSpent(
          userId,
          categoryId,
          budget.startDate,
          budget.endDate,
        );
        await this.prisma.budget.update({
          where: { id: budget.id },
          data: { spent },
        });
        await this.notifyThreshold(
          userId,
          budget.category.name,
          budget.id,
          Number(budget.amount),
          Number(budget.spent),
          spent,
        );
      } catch (err) {
        this.logger.error(`Bütçe ${budget.id} güncellenemedi: ${err}`);
      }
    }
  }

  private async calcSpent(
    userId: string,
    categoryId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<number> {
    const result = await this.prisma.transaction.aggregate({
      where: {
        userId,
        categoryId,
        type: TransactionType.EXPENSE,
        // Ortak bütçeye atanan işlemler kişisel toplama dahil değil — çift sayım engellenir.
        sharedBudgetId: null,
        transactionDate: {
          gte: startDate,
          lte: endDate,
        },
      },
      _sum: { amount: true },
    });
    return Number(result._sum.amount ?? 0);
  }

  private async notifyPersonalArchive(b: {
    id: string;
    userId: string;
    name: string;
    amount: unknown;
    spent: unknown;
  }) {
    const amount = Number(b.amount);
    const spent = Number(b.spent);
    const pct = amount > 0 ? Math.round((spent / amount) * 100) : 0;
    const exceeded = spent > amount;

    const title = exceeded
      ? 'Bütçe dönemi kapandı (aşıldı)'
      : 'Bütçe dönemi kapandı';
    const body = exceeded
      ? `${b.name}: ${spent.toFixed(0)}₺/${amount.toFixed(0)}₺ — %${pct} ile kapandı. Yeni dönem için tutarı ayarlamak ister misin?`
      : `${b.name}: ${spent.toFixed(0)}₺/${amount.toFixed(0)}₺ ile bitirdin. Yeni dönem için yenisini oluşturmak ister misin?`;

    await this.notifications.sendToUser(b.userId, title, body, {
      type: 'BUDGET_CLOSED',
      scope: 'personal',
      closedBudgetId: b.id,
    });
  }

  private async notifySharedArchive(b: {
    id: string;
    groupId: string;
    name: string;
    amount: unknown;
    spent: unknown;
    group: { name: string; members: { userId: string }[] };
  }) {
    const amount = Number(b.amount);
    const spent = Number(b.spent);
    const pct = amount > 0 ? Math.round((spent / amount) * 100) : 0;
    const exceeded = spent > amount;

    const title = exceeded ? 'Ortak bütçe aşıldı' : 'Ortak bütçe kapandı';
    const body = exceeded
      ? `${b.group.name} · ${b.name}: ${spent.toFixed(0)}₺/${amount.toFixed(0)}₺ — %${pct} ile kapandı.`
      : `${b.group.name} · ${b.name}: ${spent.toFixed(0)}₺/${amount.toFixed(0)}₺ ile bitti.`;

    for (const member of b.group.members) {
      await this.notifications.sendToUser(member.userId, title, body, {
        type: 'BUDGET_CLOSED',
        scope: 'shared',
        closedSharedBudgetId: b.id,
        groupId: b.groupId,
      });
    }
  }

  private async notifyThreshold(
    userId: string,
    categoryName: string,
    budgetId: string,
    amount: number,
    oldSpent: number,
    newSpent: number,
  ) {
    if (amount <= 0) return;
    const oldPct = (oldSpent / amount) * 100;
    const newPct = (newSpent / amount) * 100;
    // Yalnızca eşiği bu güncellemede AŞARSAK bildir — aynı eşikte kalan
    // veya azalan harcamalarda spam atmayalım. Kullanıcı %100'ün üzerinde
    // sabitse her yeni işlemde tekrar "aştınız" almasın.
    const crossed = (threshold: number) =>
      oldPct < threshold && newPct >= threshold;

    if (crossed(100)) {
      this.logger.warn(`Bütçe aşıldı [${budgetId}] — %${Math.round(newPct)}`);
      await this.notifications.sendToUser(
        userId,
        'Bütçe Aşıldı!',
        `${categoryName} bütçenizi %${Math.round(newPct)} oranında aştınız.`,
      );
    } else if (crossed(90)) {
      this.logger.warn(`Bütçe kritik [${budgetId}] — %${Math.round(newPct)}`);
      await this.notifications.sendToUser(
        userId,
        'Bütçe Kritik Seviyede',
        `${categoryName} bütçenizin %${Math.round(newPct)}'ini harcadınız.`,
      );
    } else if (crossed(80)) {
      this.logger.log(`Bütçe uyarısı [${budgetId}] — %${Math.round(newPct)}`);
      await this.notifications.sendToUser(
        userId,
        'Bütçe Uyarısı',
        `${categoryName} bütçenizin %${Math.round(newPct)}'ini harcadınız.`,
      );
    }
  }

  // =============================================
  // Enflasyon — Öneri & Uygulama
  // =============================================

  async getInflationSuggestion(userId: string, id: string) {
    const budget = await this.findOwned(userId, id);

    const inflationMap = await this.prisma.categoryInflationMap.findUnique({
      where: { categoryId: budget.categoryId },
    });

    if (!inflationMap) {
      throw new UnprocessableEntityException(
        'Bu kategori için enflasyon eşleştirmesi tanımlı değil',
      );
    }

    const now = new Date();
    const updatedAt = budget.updatedAt;
    const monthsSinceUpdate = Math.max(
      1,
      (now.getFullYear() - updatedAt.getFullYear()) * 12 +
        (now.getMonth() - updatedAt.getMonth()),
    );

    const monthPairs = this.buildMonthPairsSince(updatedAt, now);
    const rates = await this.prisma.inflationRate.findMany({
      where: {
        categoryKey: inflationMap.inflationKey,
        OR: monthPairs.map(({ year, month }) => ({ year, month })),
      },
      orderBy: [{ year: 'asc' }, { month: 'asc' }],
    });

    let cumulativeMultiplier = 1;
    for (const rate of rates) {
      cumulativeMultiplier *= 1 + Number(rate.monthlyRate) / 100;
    }
    const cumulativeRate =
      Math.round((cumulativeMultiplier - 1) * 100 * 100) / 100;

    const currentAmount = Number(budget.amount);
    const suggestedAmount =
      Math.round(currentAmount * cumulativeMultiplier * 100) / 100;

    if (cumulativeRate < 5 && suggestedAmount - currentAmount < 100) {
      return null;
    }

    return {
      budgetId: budget.id,
      currentAmount,
      suggestedAmount,
      cumulativeRate,
      monthsSinceUpdate,
      categoryKey: inflationMap.inflationKey,
    };
  }

  async applyInflation(userId: string, id: string, dto: ApplyInflationDto) {
    const suggestion = await this.getInflationSuggestion(userId, id);

    if (!suggestion) {
      throw new BadRequestException(
        'Enflasyon düzeltmesi anlamlı eşiğin altında',
      );
    }

    const lower = Math.round(suggestion.suggestedAmount * 0.9 * 100) / 100;
    const upper = Math.round(suggestion.suggestedAmount * 1.1 * 100) / 100;
    if (dto.newAmount < lower || dto.newAmount > upper) {
      throw new BadRequestException(
        `Yeni tutar önerilen değerin (${suggestion.suggestedAmount} TL) ±%10 dışında olamaz`,
      );
    }

    return this.update(userId, id, { amount: dto.newAmount });
  }

  private buildMonthPairsSince(
    from: Date,
    to: Date,
  ): { year: number; month: number }[] {
    const pairs: { year: number; month: number }[] = [];
    // updatedAt'ten SONRAKİ aydan başla, to'nun ayına kadar
    let d = new Date(from.getFullYear(), from.getMonth() + 1, 1);
    const limit = new Date(to.getFullYear(), to.getMonth() + 1, 1);
    while (d < limit) {
      pairs.push({ year: d.getFullYear(), month: d.getMonth() + 1 });
      d = new Date(d.getFullYear(), d.getMonth() + 1, 1);
    }
    return pairs;
  }

  private async findOwned(userId: string, id: string) {
    const budget = await this.prisma.budget.findFirst({
      where: { id, userId },
      include: { category: true },
    });
    if (!budget) throw new NotFoundException('Bütçe bulunamadı');
    return budget;
  }

  private format(b: {
    amount: unknown;
    spent: unknown;
    [key: string]: unknown;
  }) {
    const amount = Number(b.amount);
    const spent = Number(b.spent);
    const remaining = amount - spent;
    const percentage = amount > 0 ? Math.round((spent / amount) * 100) : 0;
    const status =
      percentage >= 100
        ? 'EXCEEDED'
        : percentage >= 90
          ? 'CRITICAL'
          : percentage >= 80
            ? 'WARNING'
            : 'OK';

    return { ...b, amount, spent, remaining, percentage, status };
  }
}
