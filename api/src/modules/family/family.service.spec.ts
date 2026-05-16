/* eslint-disable */
import {
  BadRequestException,
  ForbiddenException,
  HttpException,
  NotFoundException,
} from '@nestjs/common';
import { FamilyRole, InviteStatus } from '@prisma/client';
import { FamilyService } from './family.service';

const mockPrisma = {
  familyMember: {
    count: jest.fn(),
    findMany: jest.fn(),
    findFirst: jest.fn(),
    create: jest.fn(),
    delete: jest.fn(),
  },
  familyGroup: {
    create: jest.fn(),
    findUnique: jest.fn(),
    findFirst: jest.fn(),
    findMany: jest.fn(),
  },
  familyInvite: {
    findFirst: jest.fn(),
    findUnique: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    updateMany: jest.fn(),
    delete: jest.fn(),
  },
  sharedBudget: {
    create: jest.fn(),
    findMany: jest.fn(),
    findFirst: jest.fn(),
  },
  transaction: {
    findMany: jest.fn(),
  },
  user: {
    findUnique: jest.fn(),
  },
  $transaction: jest.fn(),
};

const mockNotificationsService = { sendToUser: jest.fn().mockResolvedValue(undefined) };

const OWNER_ID = 'owner-1';
const MEMBER_ID = 'member-1';
const GROUP_ID = 'group-1';
const TOKEN = 'invite-token-uuid';

const baseGroup = {
  id: GROUP_ID,
  name: 'Ev Bütçesi',
  icon: 'home',
  createdAt: new Date(),
  updatedAt: new Date(),
  members: [{ id: 'm1' }],
};

const ownerMember = {
  id: 'm1',
  groupId: GROUP_ID,
  userId: OWNER_ID,
  role: FamilyRole.OWNER,
  joinedAt: new Date(),
};

const memberMember = {
  id: 'm2',
  groupId: GROUP_ID,
  userId: MEMBER_ID,
  role: FamilyRole.MEMBER,
  joinedAt: new Date(),
};

const basePendingInvite = {
  id: 'invite-1',
  groupId: GROUP_ID,
  invitedBy: OWNER_ID,
  email: 'ayse@example.com',
  token: TOKEN,
  status: InviteStatus.PENDING,
  expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
  createdAt: new Date(),
};

describe('FamilyService', () => {
  let service: FamilyService;

  beforeEach(() => {
    service = new FamilyService(mockPrisma as any, mockNotificationsService as any);
    jest.clearAllMocks();
    mockPrisma.$transaction.mockImplementation(async (cb: any) => cb(mockPrisma));
  });

  // ─── createGroup ─────────────────────────────────────────────────────────────

  describe('createGroup()', () => {
    it('başarılı: grup oluşturulur ve OWNER üye eklenir', async () => {
      mockPrisma.familyMember.count.mockResolvedValue(0);
      mockPrisma.familyGroup.create.mockResolvedValue({
        ...baseGroup,
        members: [{ id: 'm1' }],
      });
      mockPrisma.familyMember.findFirst.mockResolvedValue(ownerMember);

      const result = await service.createGroup(OWNER_ID, { name: 'Ev Bütçesi', icon: 'home' });

      expect(result.name).toBe('Ev Bütçesi');
      expect(result.role).toBe('OWNER');
      expect(result.memberCount).toBe(1);
    });

    it('limit aşıldığında BadRequestException fırlatır', async () => {
      mockPrisma.familyMember.count.mockResolvedValue(3); // MAX_GROUPS_PER_USER = 3

      await expect(
        service.createGroup(OWNER_ID, { name: 'Yeni Grup' }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // ─── sendInvite ──────────────────────────────────────────────────────────────

  describe('sendInvite()', () => {
    const dto = { email: 'ayse@example.com' };

    beforeEach(() => {
      mockPrisma.familyMember.findFirst.mockResolvedValue(ownerMember);
      mockPrisma.familyMember.count.mockResolvedValue(2);
      mockPrisma.familyInvite.findFirst.mockResolvedValue(null);
      mockPrisma.familyGroup.findUnique.mockResolvedValue({ name: 'Ev Bütçesi' });
      mockPrisma.user.findUnique.mockResolvedValue({ fullName: 'Batuhan' });
      mockPrisma.familyInvite.create.mockResolvedValue(basePendingInvite);
    });

    it('başarılı: davet oluşturulur ve e-posta gönderilir', async () => {
      // requireMember → ownerMember; alreadyMember check → null (farklı kullanıcı)
      mockPrisma.familyMember.findFirst
        .mockResolvedValueOnce(ownerMember)
        .mockResolvedValueOnce(null);

      const result = await service.sendInvite(OWNER_ID, GROUP_ID, dto);

      expect(result.email).toBe(dto.email);
      expect(result.status).toBe('PENDING');
      expect(mockNotificationsService.sendToUser).toHaveBeenCalledTimes(1);
    });

    it('OWNER değilse ForbiddenException', async () => {
      mockPrisma.familyMember.findFirst.mockResolvedValue(memberMember);

      await expect(service.sendInvite(MEMBER_ID, GROUP_ID, dto)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('üye limiti aşıldığında BadRequestException', async () => {
      mockPrisma.familyMember.count.mockResolvedValue(5); // MAX_MEMBERS = 5

      await expect(service.sendInvite(OWNER_ID, GROUP_ID, dto)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('aynı e-postaya pending davet varsa eski davet EXPIRED yapılır ve yeni davet gönderilir', async () => {
      mockPrisma.familyMember.findFirst
        .mockResolvedValueOnce(ownerMember)
        .mockResolvedValueOnce(null);
      mockPrisma.familyInvite.updateMany.mockResolvedValue({ count: 1 });

      const result = await service.sendInvite(OWNER_ID, GROUP_ID, dto);

      expect(mockPrisma.familyInvite.updateMany).toHaveBeenCalledWith({
        where: {
          groupId: GROUP_ID,
          email: dto.email,
          status: InviteStatus.PENDING,
        },
        data: { status: InviteStatus.EXPIRED },
      });
      expect(result.status).toBe('PENDING');
    });
  });

  // ─── cancelInvite ──────────────────────────────────────────────────────────

  describe('cancelInvite()', () => {
    it('owner pending daveti iptal edebilir', async () => {
      mockPrisma.familyInvite.findUnique.mockResolvedValue(basePendingInvite);
      mockPrisma.familyMember.findFirst.mockResolvedValue(ownerMember);

      const result = await service.cancelInvite(OWNER_ID, TOKEN);

      expect(result).toBeNull();
      expect(mockPrisma.familyInvite.delete).toHaveBeenCalledWith({
        where: { id: basePendingInvite.id },
      });
    });

    it('davet bulunamazsa NotFoundException', async () => {
      mockPrisma.familyInvite.findUnique.mockResolvedValue(null);

      await expect(service.cancelInvite(OWNER_ID, TOKEN)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('owner değilse ForbiddenException', async () => {
      mockPrisma.familyInvite.findUnique.mockResolvedValue(basePendingInvite);
      mockPrisma.familyMember.findFirst.mockResolvedValue(memberMember);

      await expect(service.cancelInvite(MEMBER_ID, TOKEN)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('pending olmayan daveti iptal etmeye çalışmak BadRequestException', async () => {
      mockPrisma.familyInvite.findUnique.mockResolvedValue({
        ...basePendingInvite,
        status: InviteStatus.ACCEPTED,
      });
      mockPrisma.familyMember.findFirst.mockResolvedValue(ownerMember);

      await expect(service.cancelInvite(OWNER_ID, TOKEN)).rejects.toThrow(
        BadRequestException,
      );
    });
  });

  // ─── acceptInvite ─────────────────────────────────────────────────────────────

  describe('acceptInvite()', () => {
    beforeEach(() => {
      mockPrisma.familyInvite.findUnique.mockResolvedValue(basePendingInvite);
      mockPrisma.user.findUnique.mockResolvedValue({ email: 'ayse@example.com', fullName: 'Ayşe' });
      mockPrisma.familyGroup.findUnique.mockResolvedValue({
        ...baseGroup,
        members: [{ id: 'm1' }, { id: 'm2' }],
      });
      mockPrisma.familyMember.findFirst.mockResolvedValue(memberMember);
    });

    it('başarılı: davet kabul edilir ve üye eklenir', async () => {
      const result = await service.acceptInvite(MEMBER_ID, TOKEN);

      expect(mockPrisma.$transaction).toHaveBeenCalledTimes(1);
      expect(result.name).toBe('Ev Bütçesi');
    });

    it('e-posta eşleşmezse ForbiddenException', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({ email: 'baska@example.com' });

      await expect(service.acceptInvite(MEMBER_ID, TOKEN)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('süresi dolmuş davet HttpException 410 fırlatır', async () => {
      mockPrisma.familyInvite.findUnique.mockResolvedValue({
        ...basePendingInvite,
        expiresAt: new Date(Date.now() - 1000), // geçmiş tarih
      });
      mockPrisma.familyInvite.update.mockResolvedValue({});

      await expect(service.acceptInvite(MEMBER_ID, TOKEN)).rejects.toThrow(
        HttpException,
      );

      expect(mockPrisma.familyInvite.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: { status: InviteStatus.EXPIRED },
        }),
      );
    });
  });

  // ─── getContributions ────────────────────────────────────────────────────────

  describe('getContributions()', () => {
    it('üye katkılarını toplar ve yüzde hesaplar', async () => {
      mockPrisma.familyMember.findFirst.mockResolvedValue(ownerMember);
      mockPrisma.familyMember.findMany.mockResolvedValue([
        { userId: OWNER_ID, user: { id: OWNER_ID, fullName: 'Batuhan' }, joinedAt: new Date() },
        { userId: MEMBER_ID, user: { id: MEMBER_ID, fullName: 'Ayşe' }, joinedAt: new Date() },
      ]);
      mockPrisma.transaction.findMany.mockResolvedValue([
        {
          userId: OWNER_ID,
          amount: 3200,
          sharedBudget: { category: { name: 'Market' } },
        },
        {
          userId: MEMBER_ID,
          amount: 1800,
          sharedBudget: { category: { name: 'Faturalar' } },
        },
      ]);

      const result = await service.getContributions(OWNER_ID, GROUP_ID, '2026-05');

      expect(result.period).toBe('2026-05');
      expect(result.members).toHaveLength(2);

      const batuhan = result.members.find((m) => m.userId === OWNER_ID)!;
      expect(batuhan.totalAmount).toBe(3200);
      expect(batuhan.percentage).toBe(64);

      const ayse = result.members.find((m) => m.userId === MEMBER_ID)!;
      expect(ayse.totalAmount).toBe(1800);
      expect(ayse.percentage).toBe(36);
    });
  });

  // ─── removeMember ────────────────────────────────────────────────────────────

  describe('removeMember()', () => {
    it('başarılı: üye çıkarılır', async () => {
      mockPrisma.familyMember.findFirst
        .mockResolvedValueOnce(ownerMember) // requireOwner → requireMember
        .mockResolvedValueOnce(memberMember); // target member lookup
      mockPrisma.familyMember.delete.mockResolvedValue(memberMember);

      const result = await service.removeMember(OWNER_ID, GROUP_ID, MEMBER_ID);

      expect(mockPrisma.familyMember.delete).toHaveBeenCalledWith(
        expect.objectContaining({ where: { id: memberMember.id } }),
      );
      expect(result).toBeNull();
    });

    it('OWNER kendini çıkaramaz — BadRequestException', async () => {
      mockPrisma.familyMember.findFirst.mockResolvedValue(ownerMember);

      await expect(
        service.removeMember(OWNER_ID, GROUP_ID, OWNER_ID),
      ).rejects.toThrow(BadRequestException);
    });
  });
});
