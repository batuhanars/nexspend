/* eslint-disable @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-argument */
import { randomUUID } from 'crypto';
import {
  BadRequestException,
  ForbiddenException,
  HttpException,
  HttpStatus,
  Injectable,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import {
  FamilyGroup,
  FamilyInvite,
  FamilyMember,
  FamilyRole,
  InviteStatus,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { FAMILY_CONSTANTS } from './family.constants';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateGroupDto } from './dto/create-group.dto';
import { SendInviteDto } from './dto/send-invite.dto';
import { CreateSharedBudgetDto } from './dto/create-shared-budget.dto';

@Injectable()
export class FamilyService {
  private readonly logger = new Logger(FamilyService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

  // ─── Grup CRUD ────────────────────────────────────────────────────────────────

  async createGroup(userId: string, dto: CreateGroupDto) {
    const count = await this.prisma.familyMember.count({ where: { userId } });
    if (count >= FAMILY_CONSTANTS.MAX_GROUPS_PER_USER) {
      throw new BadRequestException(
        `En fazla ${FAMILY_CONSTANTS.MAX_GROUPS_PER_USER} gruba üye olunabilir`,
      );
    }

    const group = await this.prisma.familyGroup.create({
      data: {
        name: dto.name,
        icon: dto.icon ?? null,
        members: {
          create: { userId, role: FamilyRole.OWNER },
        },
      },
      include: { members: { select: { id: true } } },
    });

    const member = await this.prisma.familyMember.findFirst({
      where: { groupId: group.id, userId },
    });

    return this.formatGroup(group, member!);
  }

  async findGroups(userId: string) {
    const members = await this.prisma.familyMember.findMany({
      where: { userId },
      include: {
        group: {
          include: { members: { select: { id: true } } },
        },
      },
      orderBy: { joinedAt: 'desc' },
    });

    return members.map((m) => this.formatGroup(m.group, m));
  }

  async findGroup(userId: string, groupId: string) {
    const group = await this.prisma.familyGroup.findFirst({
      where: { id: groupId, members: { some: { userId } } },
      include: {
        members: {
          include: {
            user: { select: { id: true, fullName: true, email: true } },
          },
          orderBy: { joinedAt: 'asc' },
        },
        sharedBudgets: {
          where: { isActive: true },
          include: { category: { select: { name: true } } },
          orderBy: { createdAt: 'desc' },
        },
        invites: {
          where: { status: InviteStatus.PENDING },
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!group) throw new ForbiddenException('Bu gruba erişim yetkiniz yok');

    const myMember = group.members.find((m) => m.userId === userId)!;
    const isOwner = myMember.role === FamilyRole.OWNER;

    return {
      id: group.id,
      name: group.name,
      icon: group.icon,
      role: myMember.role as string,
      createdAt: group.createdAt.toISOString(),
      members: group.members.map((m) => ({
        id: m.id,
        userId: m.userId,
        name: m.user.fullName,
        email: m.user.email,
        role: m.role,
        joinedAt: m.joinedAt.toISOString(),
      })),
      sharedBudgets: group.sharedBudgets.map((b) =>
        this.formatBudget(b as any),
      ),
      pendingInvites: isOwner
        ? group.invites.map((i) => this.formatInvite(i))
        : [],
    };
  }

  // ─── Davet ───────────────────────────────────────────────────────────────────

  async sendInvite(userId: string, groupId: string, dto: SendInviteDto) {
    await this.requireOwner(userId, groupId);

    const memberCount = await this.prisma.familyMember.count({
      where: { groupId },
    });
    if (memberCount >= FAMILY_CONSTANTS.MAX_MEMBERS) {
      throw new BadRequestException(
        `Grup üye sınırına ulaşıldı (max ${FAMILY_CONSTANTS.MAX_MEMBERS})`,
      );
    }

    const pendingDuplicate = await this.prisma.familyInvite.findFirst({
      where: { groupId, email: dto.email, status: InviteStatus.PENDING },
    });
    if (pendingDuplicate) {
      throw new BadRequestException(
        'Bu e-postaya zaten bekleyen bir davet var',
      );
    }

    const alreadyMember = await this.prisma.familyMember.findFirst({
      where: { groupId, user: { email: dto.email } },
    });
    if (alreadyMember) {
      throw new BadRequestException('Bu kullanıcı zaten grup üyesi');
    }

    const expiresAt = new Date();
    expiresAt.setDate(
      expiresAt.getDate() + FAMILY_CONSTANTS.INVITE_EXPIRY_DAYS,
    );

    const invite = await this.prisma.familyInvite.create({
      data: {
        groupId,
        invitedBy: userId,
        email: dto.email,
        token: randomUUID(),
        status: InviteStatus.PENDING,
        expiresAt,
      },
    });

    const invitedUser = await this.prisma.user.findUnique({
      where: { email: dto.email },
      select: { id: true },
    });

    if (invitedUser) {
      const group = await this.prisma.familyGroup.findUnique({
        where: { id: groupId },
        select: { name: true },
      });
      const inviter = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { fullName: true },
      });
      await this.notifications.sendToUser(
        invitedUser.id,
        'Aile Bütçesi Daveti',
        `${inviter!.fullName} sizi "${group!.name}" grubuna davet etti`,
        { type: 'FAMILY_INVITE', inviteToken: invite.token },
      );
    }

    return this.formatInvite(invite);
  }

  async acceptInvite(userId: string, token: string) {
    const invite = await this.prisma.familyInvite.findUnique({
      where: { token },
    });
    if (!invite) throw new NotFoundException('Davet bulunamadı');

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { email: true, fullName: true },
    });

    if (user?.email !== invite.email) {
      throw new ForbiddenException('Bu davet size ait değil');
    }

    if (invite.status !== InviteStatus.PENDING) {
      throw new BadRequestException('Bu davet artık geçerli değil');
    }

    if (invite.expiresAt < new Date()) {
      await this.prisma.familyInvite.update({
        where: { id: invite.id },
        data: { status: InviteStatus.EXPIRED },
      });
      throw new HttpException('Davet süresi dolmuş', HttpStatus.GONE);
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.familyInvite.update({
        where: { id: invite.id },
        data: { status: InviteStatus.ACCEPTED },
      });
      await tx.familyMember.create({
        data: { groupId: invite.groupId, userId, role: FamilyRole.MEMBER },
      });
    });

    const group = await this.prisma.familyGroup.findUnique({
      where: { id: invite.groupId },
      include: { members: { select: { id: true } } },
    });
    const member = await this.prisma.familyMember.findFirst({
      where: { groupId: invite.groupId, userId },
    });

    const result = this.formatGroup(group!, member!);

    // Fire-and-forget: inviter'a kabul bildirimi gönder
    this.notifications
      .sendToUser(
        invite.invitedBy,
        'Davet Kabul Edildi',
        `${user?.fullName ?? invite.email} grubunuza katıldı`,
        {
          type: 'INVITE_RESPONSE',
          status: 'ACCEPTED',
          groupId: invite.groupId,
        },
      )
      .catch((err: unknown) =>
        this.logger.warn(`Davet kabul bildirimi gönderilemedi: ${String(err)}`),
      );

    return result;
  }

  async rejectInvite(userId: string, token: string) {
    const invite = await this.prisma.familyInvite.findUnique({
      where: { token },
    });
    if (!invite) throw new NotFoundException('Davet bulunamadı');

    if (invite.status !== InviteStatus.PENDING) {
      throw new BadRequestException('Bu davet artık geçerli değil');
    }

    await this.prisma.familyInvite.update({
      where: { id: invite.id },
      data: { status: InviteStatus.REJECTED },
    });

    const group = await this.prisma.familyGroup.findUnique({
      where: { id: invite.groupId },
      select: { name: true },
    });

    // Fire-and-forget: inviter'a red bildirimi gönder
    this.notifications
      .sendToUser(
        invite.invitedBy,
        'Davet Reddedildi',
        `"${group?.name ?? ''}" grubuna gönderilen davet reddedildi`,
        {
          type: 'INVITE_RESPONSE',
          status: 'REJECTED',
          groupId: invite.groupId,
        },
      )
      .catch((err: unknown) =>
        this.logger.warn(`Davet red bildirimi gönderilemedi: ${String(err)}`),
      );

    return null;
  }

  // ─── Ortak Bütçe ─────────────────────────────────────────────────────────────

  async createSharedBudget(
    userId: string,
    groupId: string,
    dto: CreateSharedBudgetDto,
  ) {
    await this.requireMember(userId, groupId);

    const budget = await this.prisma.sharedBudget.create({
      data: {
        groupId,
        categoryId: dto.categoryId,
        name: dto.name,
        amount: dto.amount,
        startDate: new Date(dto.startDate),
      },
      include: { category: { select: { name: true } } },
    });

    return this.formatBudget(budget);
  }

  async findSharedBudgets(
    userId: string,
    groupId: string,
    includeInactive: boolean,
  ) {
    await this.requireMember(userId, groupId);

    const budgets = await this.prisma.sharedBudget.findMany({
      where: {
        groupId,
        ...(includeInactive ? {} : { isActive: true }),
      },
      include: { category: { select: { name: true } } },
      orderBy: { createdAt: 'desc' },
    });

    return budgets.map((b) => this.formatBudget(b as any));
  }

  // ─── Katkı Raporu ─────────────────────────────────────────────────────────────

  async getContributions(userId: string, groupId: string, period?: string) {
    await this.requireMember(userId, groupId);

    const targetPeriod = period ?? this.currentPeriod();
    const { start, end } = this.periodToDateRange(targetPeriod);

    const members = await this.prisma.familyMember.findMany({
      where: { groupId },
      include: { user: { select: { id: true, fullName: true } } },
      orderBy: { joinedAt: 'asc' },
    });

    const expenses = await this.prisma.sharedExpense.findMany({
      where: {
        sharedBudget: { groupId },
        createdAt: { gte: start, lte: end },
      },
      include: {
        sharedBudget: {
          include: { category: { select: { name: true } } },
        },
      },
    });

    const byUser = new Map<
      string,
      { total: number; categories: Map<string, number> }
    >();

    for (const exp of expenses) {
      const uid = exp.userId;
      const catName = exp.sharedBudget.category.name;
      const amount = Number(exp.amount);

      if (!byUser.has(uid))
        byUser.set(uid, { total: 0, categories: new Map() });
      const entry = byUser.get(uid)!;
      entry.total += amount;
      entry.categories.set(
        catName,
        (entry.categories.get(catName) ?? 0) + amount,
      );
    }

    const grandTotal = Array.from(byUser.values()).reduce(
      (s, v) => s + v.total,
      0,
    );

    const result = members.map((m) => {
      const data = byUser.get(m.userId);
      const total = data?.total ?? 0;
      const pct =
        grandTotal > 0 ? Math.round((total / grandTotal) * 100 * 10) / 10 : 0;
      const byCategory = data
        ? Array.from(data.categories.entries()).map(
            ([categoryName, amount]) => ({
              categoryName,
              amount: Math.round(amount * 100) / 100,
            }),
          )
        : [];

      return {
        userId: m.userId,
        name: m.user.fullName,
        totalAmount: Math.round(total * 100) / 100,
        percentage: pct,
        byCategory,
      };
    });

    return { period: targetPeriod, members: result };
  }

  // ─── Üye Yönetimi ────────────────────────────────────────────────────────────

  async removeMember(userId: string, groupId: string, targetUserId: string) {
    await this.requireOwner(userId, groupId);

    if (userId === targetUserId) {
      throw new BadRequestException('Grup sahibi kendini çıkaramaz');
    }

    const target = await this.prisma.familyMember.findFirst({
      where: { groupId, userId: targetUserId },
    });
    if (!target) throw new NotFoundException('Üye bulunamadı');

    await this.prisma.familyMember.delete({ where: { id: target.id } });
    return null;
  }

  async deleteGroup(userId: string, groupId: string): Promise<null> {
    await this.requireOwner(userId, groupId);
    await this.prisma.familyGroup.delete({ where: { id: groupId } });
    return null;
  }

  async deleteSharedBudget(
    userId: string,
    groupId: string,
    budgetId: string,
  ): Promise<null> {
    await this.requireMember(userId, groupId);
    const budget = await this.prisma.sharedBudget.findFirst({
      where: { id: budgetId, groupId },
    });
    if (!budget) throw new NotFoundException('Bütçe bulunamadı');
    await this.prisma.sharedBudget.delete({ where: { id: budgetId } });
    return null;
  }

  // ─── Ortak Bütçe — İşlem Listesi ─────────────────────────────────────────────

  async findSharedBudgetExpenses(
    userId: string,
    groupId: string,
    budgetId: string,
  ) {
    await this.requireMember(userId, groupId);

    const budget = await this.prisma.sharedBudget.findFirst({
      where: { id: budgetId, groupId },
      include: { category: { select: { name: true, icon: true } } },
    });
    if (!budget) throw new NotFoundException('Bütçe bulunamadı');

    const expenses = await this.prisma.sharedExpense.findMany({
      where: { sharedBudgetId: budgetId },
      orderBy: { createdAt: 'desc' },
    });

    if (expenses.length === 0) {
      return { budget: this.formatBudget(budget), expenses: [] };
    }

    const userIds = Array.from(new Set(expenses.map((e) => e.userId)));
    const transactionIds = Array.from(
      new Set(expenses.map((e) => e.transactionId)),
    );

    const [users, transactions] = await Promise.all([
      this.prisma.user.findMany({
        where: { id: { in: userIds } },
        select: { id: true, fullName: true },
      }),
      this.prisma.transaction.findMany({
        where: { id: { in: transactionIds } },
        select: { id: true, note: true, transactionDate: true },
      }),
    ]);

    const userMap = new Map(users.map((u) => [u.id, u.fullName]));
    const txMap = new Map(transactions.map((t) => [t.id, t]));

    const formatted = expenses.map((e) => {
      const tx = txMap.get(e.transactionId);
      return {
        id: e.id,
        transactionId: e.transactionId,
        userId: e.userId,
        userName: userMap.get(e.userId) ?? 'Bilinmeyen üye',
        amount: Number(e.amount),
        note: tx?.note ?? null,
        transactionDate: (tx?.transactionDate ?? e.createdAt).toISOString(),
        createdAt: e.createdAt.toISOString(),
      };
    });

    return { budget: this.formatBudget(budget), expenses: formatted };
  }

  // ─── Private Helpers ─────────────────────────────────────────────────────────

  private async requireMember(userId: string, groupId: string) {
    const member = await this.prisma.familyMember.findFirst({
      where: { groupId, userId },
    });
    if (!member) throw new ForbiddenException('Bu gruba erişim yetkiniz yok');
    return member;
  }

  private async requireOwner(userId: string, groupId: string) {
    const member = await this.requireMember(userId, groupId);
    if (member.role !== FamilyRole.OWNER) {
      throw new ForbiddenException(
        'Bu işlem için grup sahibi olmanız gerekiyor',
      );
    }
    return member;
  }

  private formatGroup(
    group: FamilyGroup & { members: { id: string }[] },
    member: FamilyMember,
  ) {
    return {
      id: group.id,
      name: group.name,
      icon: group.icon,
      memberCount: group.members.length,
      role: member.role as string,
      createdAt: group.createdAt.toISOString(),
    };
  }

  private formatBudget(budget: {
    id: string;
    groupId: string;
    categoryId: string;
    name: string;
    amount: unknown;
    spent: unknown;
    period: string;
    startDate: Date;
    isActive: boolean;
    category: { name: string };
  }) {
    const amount = Number(budget.amount);
    const spent = Number(budget.spent);
    const remainingPercent =
      amount > 0 ? Math.round(((amount - spent) / amount) * 100) : 100;

    return {
      id: budget.id,
      groupId: budget.groupId,
      categoryId: budget.categoryId,
      categoryName: budget.category.name,
      name: budget.name,
      amount,
      spent,
      remainingPercent,
      period: budget.period,
      startDate: budget.startDate.toISOString().split('T')[0],
      isActive: budget.isActive,
    };
  }

  private formatInvite(invite: FamilyInvite) {
    return {
      id: invite.id,
      groupId: invite.groupId,
      email: invite.email,
      status: invite.status as string,
      expiresAt: invite.expiresAt.toISOString(),
      createdAt: invite.createdAt.toISOString(),
      inviteLink: `nexspend://invite/${invite.token}`,
    };
  }

  private currentPeriod(): string {
    const now = new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  }

  private parsePeriod(period: string): { year: number; month: number } {
    const [y, m] = period.split('-').map(Number);
    return { year: y, month: m };
  }

  private periodToDateRange(period: string): { start: Date; end: Date } {
    const { year, month } = this.parsePeriod(period);
    return {
      start: new Date(year, month - 1, 1),
      end: new Date(year, month, 0, 23, 59, 59, 999),
    };
  }
}
