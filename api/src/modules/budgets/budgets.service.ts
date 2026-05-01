import {
  Injectable,
  NotFoundException,
  ConflictException,
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

@Injectable()
export class BudgetsService {
  private readonly logger = new Logger(BudgetsService.name);

  constructor(private readonly prisma: PrismaService) {}

  async findAll(userId: string) {
    const budgets = await this.prisma.budget.findMany({
      where: { userId, isActive: true },
      include: { category: true },
      orderBy: { createdAt: 'desc' },
    });
    return budgets.map(this.format);
  }

  async getOverview(userId: string) {
    const budgets = await this.prisma.budget.findMany({
      where: { userId, isActive: true },
    });

    const totalBudget = budgets.reduce((s, b) => s + Number(b.amount), 0);
    const totalSpent = budgets.reduce((s, b) => s + Number(b.spent), 0);
    const percentage = totalBudget > 0 ? Math.round((totalSpent / totalBudget) * 100) : 0;

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

  async create(userId: string, dto: CreateBudgetDto) {
    const existing = await this.prisma.budget.findFirst({
      where: {
        userId,
        categoryId: dto.categoryId,
        isActive: true,
        startDate: { lte: new Date(dto.startDate) },
        OR: [
          { endDate: null },
          { endDate: { gte: new Date(dto.startDate) } },
        ],
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
        period: dto.period ?? 'MONTHLY',
        note: dto.note ?? null,
        smartTracking: dto.smartTracking ?? true,
        startDate: new Date(dto.startDate),
        endDate: dto.endDate ? new Date(dto.endDate) : null,
      },
      include: { category: true },
    });

    // Geçmiş işlemlerden spent hesapla
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
    await this.findOwned(userId, id);

    const updated = await this.prisma.budget.update({
      where: { id },
      data: {
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.amount !== undefined && { amount: dto.amount }),
        ...(dto.period !== undefined && { period: dto.period }),
        ...(dto.note !== undefined && { note: dto.note }),
        ...(dto.smartTracking !== undefined && { smartTracking: dto.smartTracking }),
        ...(dto.isActive !== undefined && { isActive: dto.isActive }),
        ...(dto.endDate !== undefined && { endDate: new Date(dto.endDate) }),
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
  // Event Listeners
  // =============================================

  @OnEvent('transaction.created')
  async onTransactionCreated(event: TransactionCreatedEvent) {
    if (event.type !== TransactionType.EXPENSE || !event.categoryId) return;
    await this.recalculateForCategory(event.userId, event.categoryId);
  }

  @OnEvent('transaction.deleted')
  async onTransactionDeleted(event: TransactionDeletedEvent) {
    if (event.type !== TransactionType.EXPENSE || !event.categoryId) return;
    await this.recalculateForCategory(event.userId, event.categoryId);
  }

  @OnEvent('transaction.updated')
  async onTransactionUpdated(event: TransactionUpdatedEvent) {
    const affectsOld =
      event.oldType === TransactionType.EXPENSE && event.oldCategoryId;
    const affectsNew =
      event.newType === TransactionType.EXPENSE && event.newCategoryId;

    if (!affectsOld && !affectsNew) return;

    const categories = new Set<string>();
    if (affectsOld) categories.add(event.oldCategoryId!);
    if (affectsNew) categories.add(event.newCategoryId!);

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
        this.logThreshold(budget.id, Number(budget.amount), spent);
      } catch (err) {
        this.logger.error(`Bütçe ${budget.id} güncellenemedi: ${err}`);
      }
    }
  }

  private async calcSpent(
    userId: string,
    categoryId: string,
    startDate: Date,
    endDate: Date | null,
  ): Promise<number> {
    const result = await this.prisma.transaction.aggregate({
      where: {
        userId,
        categoryId,
        type: TransactionType.EXPENSE,
        transactionDate: {
          gte: startDate,
          ...(endDate ? { lte: endDate } : {}),
        },
      },
      _sum: { amount: true },
    });
    return Number(result._sum.amount ?? 0);
  }

  private logThreshold(budgetId: string, amount: number, spent: number) {
    if (amount <= 0) return;
    const pct = (spent / amount) * 100;
    if (pct >= 100) {
      this.logger.warn(`Bütçe aşıldı [${budgetId}] — %${Math.round(pct)}`);
    } else if (pct >= 90) {
      this.logger.warn(`Bütçe kritik [${budgetId}] — %${Math.round(pct)}`);
    } else if (pct >= 80) {
      this.logger.log(`Bütçe uyarısı [${budgetId}] — %${Math.round(pct)}`);
    }
  }

  private async findOwned(userId: string, id: string) {
    const budget = await this.prisma.budget.findFirst({
      where: { id, userId },
      include: { category: true },
    });
    if (!budget) throw new NotFoundException('Bütçe bulunamadı');
    return budget;
  }

  private format(b: any) {
    const amount = Number(b.amount);
    const spent = Number(b.spent);
    const remaining = amount - spent;
    const percentage = amount > 0 ? Math.round((spent / amount) * 100) : 0;
    const status =
      percentage >= 100 ? 'EXCEEDED' : percentage >= 90 ? 'CRITICAL' : percentage >= 80 ? 'WARNING' : 'OK';

    return { ...b, amount, spent, remaining, percentage, status };
  }
}
