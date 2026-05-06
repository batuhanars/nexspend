/* eslint-disable */
import { NotFoundException, BadRequestException } from '@nestjs/common';
import { DebtType, DebtStatus, TransactionType } from '@prisma/client';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { DebtsService } from './debts.service';
import { BalanceService } from '../../common/services/balance.service';

const mockPrisma = {
  debt: {
    findMany: jest.fn(),
    findFirst: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    updateMany: jest.fn(),
    delete: jest.fn(),
    findUniqueOrThrow: jest.fn(),
  },
  debtInstallment: {
    createMany: jest.fn(),
    findFirst: jest.fn(),
    update: jest.fn(),
    updateMany: jest.fn(),
    findMany: jest.fn(),
  },
  debtPayment: {
    create: jest.fn(),
    findMany: jest.fn(),
  },
  category: {
    findFirst: jest.fn(),
  },
  account: {
    update: jest.fn(),
  },
  transaction: {
    create: jest.fn(),
  },
  $transaction: jest.fn(),
};

const mockBalanceService = {
  apply: jest.fn(),
  revert: jest.fn(),
};

const mockEventEmitter = {
  emit: jest.fn(),
};

const USER_ID = 'user-1';
const DEBT_ID = 'debt-1';
const ACCOUNT_ID = 'acc-1';

const baseBorrowedDebt = {
  id: DEBT_ID,
  userId: USER_ID,
  personName: 'Ahmet',
  type: DebtType.BORROWED,
  totalAmount: 1000,
  paidAmount: 0,
  hasInstallments: false,
  status: DebtStatus.PENDING,
  dueDate: new Date('2026-12-31'),
  note: null,
  installments: [],
  _count: { payments: 0 },
};

const baseLentDebt = {
  ...baseBorrowedDebt,
  id: 'debt-2',
  type: DebtType.LENT,
  personName: 'Mehmet',
};

describe('DebtsService', () => {
  let service: DebtsService;

  beforeEach(() => {
    service = new DebtsService(mockPrisma as any, mockBalanceService as any, mockEventEmitter as any);
    jest.clearAllMocks();
  });

  // ─── findAll ─────────────────────────────────────────────────────────────────

  describe('findAll()', () => {
    it('kullanıcının borç listesini döner', async () => {
      mockPrisma.debt.findMany.mockResolvedValue([baseBorrowedDebt]);

      const result = await service.findAll(USER_ID);

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe(DEBT_ID);
    });
  });

  // ─── getSummary ──────────────────────────────────────────────────────────────

  describe('getSummary()', () => {
    it('alacak ve borç özetlerini doğru hesaplar', async () => {
      mockPrisma.debt.findMany.mockResolvedValue([
        { ...baseBorrowedDebt, totalAmount: 1000, paidAmount: 200 },
        { ...baseLentDebt, totalAmount: 500, paidAmount: 0 },
      ]);

      const result = await service.getSummary(USER_ID);

      expect(result.totalBorrowed).toBe(1000);
      expect(result.remainingBorrowed).toBe(800);
      expect(result.totalLent).toBe(500);
      expect(result.remainingLent).toBe(500);
    });

    it('borç yoksa sıfır döner', async () => {
      mockPrisma.debt.findMany.mockResolvedValue([]);

      const result = await service.getSummary(USER_ID);

      expect(result.totalBorrowed).toBe(0);
      expect(result.totalLent).toBe(0);
    });
  });

  // ─── findOne ─────────────────────────────────────────────────────────────────

  describe('findOne()', () => {
    it('mevcut borcu döner', async () => {
      mockPrisma.debt.findFirst.mockResolvedValue(baseBorrowedDebt);

      const result = await service.findOne(USER_ID, DEBT_ID);

      expect(result.id).toBe(DEBT_ID);
    });

    it('bulunamazsa NotFoundException fırlatır', async () => {
      mockPrisma.debt.findFirst.mockResolvedValue(null);

      await expect(service.findOne(USER_ID, 'nonexistent')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  // ─── create ──────────────────────────────────────────────────────────────────

  describe('create()', () => {
    it('taksitsiz borç oluşturur', async () => {
      const dto = {
        personName: 'Ahmet',
        type: DebtType.BORROWED,
        totalAmount: 500,
        hasInstallments: false,
      };

      const createdDebt = { ...baseBorrowedDebt, ...dto };
      mockPrisma.debt.create.mockResolvedValue(createdDebt);
      mockPrisma.debt.findUniqueOrThrow.mockResolvedValue({
        ...createdDebt,
        installments: [],
      });

      const result = await service.create(USER_ID, dto);

      expect(mockPrisma.debt.create).toHaveBeenCalled();
      expect(mockPrisma.debtInstallment.createMany).not.toHaveBeenCalled();
    });

    it('taksitli borç oluşturur ve taksitleri kaydeder', async () => {
      const dto = {
        personName: 'Banka',
        type: DebtType.BORROWED,
        totalAmount: 1200,
        hasInstallments: true,
        installmentCount: 12,
        firstInstallmentDate: '2026-02-01',
      };

      mockPrisma.debt.create.mockResolvedValue({
        ...baseBorrowedDebt,
        totalAmount: 1200,
        hasInstallments: true,
      });
      mockPrisma.debtInstallment.createMany.mockResolvedValue({ count: 12 });
      mockPrisma.debt.findUniqueOrThrow.mockResolvedValue({
        ...baseBorrowedDebt,
        totalAmount: 1200,
        hasInstallments: true,
        installments: [],
      });

      const result = await service.create(USER_ID, dto);

      expect(mockPrisma.debtInstallment.createMany).toHaveBeenCalled();
      const callArg = mockPrisma.debtInstallment.createMany.mock.calls[0][0];
      expect(callArg.data).toHaveLength(12);
    });
  });

  // ─── update ──────────────────────────────────────────────────────────────────

  describe('update()', () => {
    it('borcu günceller', async () => {
      mockPrisma.debt.findFirst.mockResolvedValue(baseBorrowedDebt);
      mockPrisma.debt.update.mockResolvedValue({
        ...baseBorrowedDebt,
        personName: 'Ali',
      });

      const result = await service.update(USER_ID, DEBT_ID, {
        personName: 'Ali',
      });

      expect(mockPrisma.debt.update).toHaveBeenCalled();
    });

    it('bulunamazsa NotFoundException fırlatır', async () => {
      mockPrisma.debt.findFirst.mockResolvedValue(null);

      await expect(service.update(USER_ID, 'bad-id', {})).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  // ─── remove ──────────────────────────────────────────────────────────────────

  describe('remove()', () => {
    it('borcu siler', async () => {
      mockPrisma.debt.findFirst.mockResolvedValue(baseBorrowedDebt);
      mockPrisma.debt.delete.mockResolvedValue(baseBorrowedDebt);

      const result = await service.remove(USER_ID, DEBT_ID);

      expect(result).toHaveProperty('message');
      expect(mockPrisma.debt.delete).toHaveBeenCalledWith({
        where: { id: DEBT_ID },
      });
    });

    it('bulunamazsa NotFoundException fırlatır', async () => {
      mockPrisma.debt.findFirst.mockResolvedValue(null);

      await expect(service.remove(USER_ID, 'bad-id')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  // ─── createPayment ───────────────────────────────────────────────────────────

  describe('createPayment()', () => {
    const paymentDto = {
      accountId: ACCOUNT_ID,
      amount: 300,
    };

    it('BORROWED borç ödemesi gider işlemi oluşturur', async () => {
      mockPrisma.debt.findFirst.mockResolvedValue(baseBorrowedDebt);
      mockPrisma.category.findFirst.mockResolvedValue({
        id: 'cat-debt',
        name: 'Borç Ödemesi',
      });
      mockPrisma.$transaction.mockImplementation(async (fn: any) => {
        const tx = {
          debtPayment: { create: jest.fn().mockResolvedValue({ id: 'pay-1' }) },
          debtInstallment: { findFirst: jest.fn(), update: jest.fn() },
          debt: { update: jest.fn().mockResolvedValue({}) },
          account: { update: jest.fn().mockResolvedValue({}) },
          transaction: {
            create: jest
              .fn()
              .mockResolvedValue({ id: 'tx-1', type: TransactionType.EXPENSE }),
          },
        };
        return fn(tx);
      });

      const result = await service.createPayment(USER_ID, DEBT_ID, paymentDto);

      expect(mockPrisma.$transaction).toHaveBeenCalled();
      expect(mockEventEmitter.emit).toHaveBeenCalledWith(
        'transaction.created',
        expect.any(Object),
      );
    });

    it('LENT alacak tahsilatı gelir işlemi oluşturur', async () => {
      mockPrisma.debt.findFirst.mockResolvedValue(baseLentDebt);
      mockPrisma.category.findFirst.mockResolvedValue({
        id: 'cat-lent',
        name: 'Alacak Tahsilatı',
      });
      mockPrisma.$transaction.mockImplementation(async (fn: any) => {
        const tx = {
          debtPayment: { create: jest.fn().mockResolvedValue({ id: 'pay-2' }) },
          debtInstallment: { findFirst: jest.fn(), update: jest.fn() },
          debt: { update: jest.fn().mockResolvedValue({}) },
          account: { update: jest.fn().mockResolvedValue({}) },
          transaction: {
            create: jest
              .fn()
              .mockResolvedValue({ id: 'tx-2', type: TransactionType.INCOME }),
          },
        };
        return fn(tx);
      });

      await service.createPayment(USER_ID, 'debt-2', paymentDto);

      expect(mockEventEmitter.emit).toHaveBeenCalled();
    });

    it('ödeme tutarı kalan borçtan fazlaysa BadRequestException fırlatır', async () => {
      mockPrisma.debt.findFirst.mockResolvedValue({
        ...baseBorrowedDebt,
        totalAmount: 500,
        paidAmount: 300,
      });

      await expect(
        service.createPayment(USER_ID, DEBT_ID, { ...paymentDto, amount: 300 }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // ─── markOverdue ─────────────────────────────────────────────────────────────

  describe('markOverdue()', () => {
    it('vadesi geçmiş borç ve taksitleri OVERDUE yapar', async () => {
      mockPrisma.debt.updateMany.mockResolvedValue({ count: 2 });
      mockPrisma.debtInstallment.updateMany.mockResolvedValue({ count: 3 });

      await service.markOverdue();

      expect(mockPrisma.debt.updateMany).toHaveBeenCalledWith(
        expect.objectContaining({ data: { status: DebtStatus.OVERDUE } }),
      );
      expect(mockPrisma.debtInstallment.updateMany).toHaveBeenCalledWith(
        expect.objectContaining({ data: { status: DebtStatus.OVERDUE } }),
      );
    });
  });
});
