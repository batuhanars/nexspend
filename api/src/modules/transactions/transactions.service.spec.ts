/* eslint-disable */
import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException, BadRequestException } from '@nestjs/common';
import { TransactionSource, TransactionType } from '@prisma/client';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { TransactionsService } from './transactions.service';
import { BalanceService } from '../../common/services/balance.service';

const mockPrisma = {
  transaction: {
    findMany: jest.fn(),
    findFirst: jest.fn(),
    count: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
    aggregate: jest.fn(),
  },
  account: {
    update: jest.fn(),
    findFirst: jest.fn(),
  },
  recurringTransaction: {
    create: jest.fn(),
  },
  transactionTag: {
    deleteMany: jest.fn(),
  },
  $transaction: jest.fn(),
};

const mockEventEmitter = {
  emit: jest.fn(),
};

const mockBalanceService = {
  apply: jest.fn(),
  revert: jest.fn(),
};

const USER_ID = 'user-1';
const ACCOUNT_ID = 'acc-1';

const baseTx = {
  id: 'tx-1',
  userId: USER_ID,
  accountId: ACCOUNT_ID,
  type: TransactionType.EXPENSE,
  amount: 100,
  title: 'Test İşlemi',
  note: null,
  categoryId: 'cat-1',
  transactionDate: new Date('2026-01-15'),
  transferToAccountId: null,
  sharedBudgetId: null,
  source: TransactionSource.MANUAL,
  tags: [],
  category: { id: 'cat-1', name: 'Market' },
  account: {
    id: ACCOUNT_ID,
    name: 'Ziraat',
    icon: 'bank',
    color: '#fff',
    type: 'BANK',
  },
  transferToAccount: null,
};

describe('TransactionsService', () => {
  let service: TransactionsService;

  beforeEach(() => {
    service = new TransactionsService(
      mockPrisma as any,
      mockBalanceService as any,
      mockEventEmitter as any,
    );
    jest.clearAllMocks();
  });

  // ─── findAll ─────────────────────────────────────────────────────────────────

  describe('findAll()', () => {
    it('sayfalı işlem listesi döner', async () => {
      mockPrisma.transaction.findMany.mockResolvedValue([baseTx]);
      mockPrisma.transaction.count.mockResolvedValue(1);

      const result = await service.findAll(USER_ID, { page: 1, limit: 20 });

      expect(result.data).toHaveLength(1);
      expect(result.total).toBe(1);
      expect(result.totalPages).toBe(1);
    });

    it('tip filtresiyle sorgu yapar', async () => {
      mockPrisma.transaction.findMany.mockResolvedValue([]);
      mockPrisma.transaction.count.mockResolvedValue(0);

      await service.findAll(USER_ID, { type: TransactionType.INCOME });

      const whereArg = mockPrisma.transaction.findMany.mock.calls[0][0].where;
      expect(whereArg.type).toBe(TransactionType.INCOME);
    });

    it('tarih aralığı filtresiyle sorgu yapar', async () => {
      mockPrisma.transaction.findMany.mockResolvedValue([]);
      mockPrisma.transaction.count.mockResolvedValue(0);

      await service.findAll(USER_ID, {
        startDate: '2026-01-01',
        endDate: '2026-01-31',
      });

      const whereArg = mockPrisma.transaction.findMany.mock.calls[0][0].where;
      expect(whereArg.transactionDate).toBeDefined();
    });

    it('arama metni filtresiyle başlık + açıklama OR sorgusu yapar', async () => {
      mockPrisma.transaction.findMany.mockResolvedValue([]);
      mockPrisma.transaction.count.mockResolvedValue(0);

      await service.findAll(USER_ID, { search: 'market' });

      const whereArg = mockPrisma.transaction.findMany.mock.calls[0][0].where;
      expect(whereArg.OR).toEqual([
        { title: { contains: 'market' } },
        { description: { contains: 'market' } },
      ]);
    });

    it('arama metni description eşleşmesiyle OR dalını içerir', async () => {
      const txWithDesc = { ...baseTx, description: 'market alışveriş notu' };
      mockPrisma.transaction.findMany.mockResolvedValue([txWithDesc]);
      mockPrisma.transaction.count.mockResolvedValue(1);

      await service.findAll(USER_ID, { search: 'alışveriş' });

      const whereArg = mockPrisma.transaction.findMany.mock.calls[0][0].where;
      expect(whereArg.OR).toBeDefined();
      expect(whereArg.OR).toContainEqual({ description: { contains: 'alışveriş' } });
    });
  });

  // ─── getSummary ──────────────────────────────────────────────────────────────

  describe('getSummary()', () => {
    it('gelir, gider ve net değeri hesaplar', async () => {
      mockPrisma.transaction.aggregate
        .mockResolvedValueOnce({ _sum: { amount: 5000 } }) // income
        .mockResolvedValueOnce({ _sum: { amount: 3000 } }); // expense

      const result = await service.getSummary(USER_ID, {});

      expect(result.income).toBe(5000);
      expect(result.expense).toBe(3000);
      expect(result.net).toBe(2000);
    });

    it('işlem yoksa sıfır döner', async () => {
      mockPrisma.transaction.aggregate
        .mockResolvedValueOnce({ _sum: { amount: null } })
        .mockResolvedValueOnce({ _sum: { amount: null } });

      const result = await service.getSummary(USER_ID, {});

      expect(result.income).toBe(0);
      expect(result.expense).toBe(0);
      expect(result.net).toBe(0);
    });
  });

  // ─── findOne ─────────────────────────────────────────────────────────────────

  describe('findOne()', () => {
    it('mevcut işlemi döner', async () => {
      mockPrisma.transaction.findFirst.mockResolvedValue(baseTx);

      const result = await service.findOne(USER_ID, 'tx-1');

      expect(result.id).toBe('tx-1');
    });

    it('bulunamazsa NotFoundException fırlatır', async () => {
      mockPrisma.transaction.findFirst.mockResolvedValue(null);

      await expect(service.findOne(USER_ID, 'nonexistent')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  // ─── create ──────────────────────────────────────────────────────────────────

  describe('create()', () => {
    it('EXPENSE işlemi oluşturur ve bakiyeyi düşer', async () => {
      const dto = {
        accountId: ACCOUNT_ID,
        type: TransactionType.EXPENSE,
        amount: 150,
        title: 'Market',
        categoryId: 'cat-1',
      };

      mockPrisma.$transaction.mockImplementation(async (fn: any) =>
        fn({
          transaction: {
            create: jest
              .fn()
              .mockResolvedValue({ ...baseTx, ...dto, tags: [] }),
          },
          account: { update: jest.fn().mockResolvedValue({}) },
        }),
      );

      const result = await service.create(USER_ID, dto);

      expect(mockPrisma.$transaction).toHaveBeenCalled();
      expect(mockEventEmitter.emit).toHaveBeenCalledWith(
        'transaction.created',
        expect.any(Object),
      );
    });

    it('INCOME işlemi oluşturur', async () => {
      const dto = {
        accountId: ACCOUNT_ID,
        type: TransactionType.INCOME,
        amount: 5000,
        title: 'Maaş',
        categoryId: 'cat-income',
      };

      mockPrisma.$transaction.mockImplementation(async (fn: any) =>
        fn({
          transaction: {
            create: jest.fn().mockResolvedValue({
              ...baseTx,
              type: TransactionType.INCOME,
              tags: [],
            }),
          },
          account: { update: jest.fn().mockResolvedValue({}) },
        }),
      );

      await service.create(USER_ID, dto);

      expect(mockEventEmitter.emit).toHaveBeenCalledWith(
        'transaction.created',
        expect.any(Object),
      );
    });

    it('TRANSFER için hedef hesap olmayınca BadRequestException fırlatır', async () => {
      const dto = {
        accountId: ACCOUNT_ID,
        type: TransactionType.TRANSFER,
        amount: 500,
        title: 'Transfer',
      };

      await expect(service.create(USER_ID, dto)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('INCOME + CREDIT_CARD hesabı → BadRequestException fırlatır', async () => {
      const dto = {
        accountId: ACCOUNT_ID,
        type: TransactionType.INCOME,
        amount: 1000,
        title: 'Yanlış Kayıt',
        categoryId: 'cat-1',
      };

      mockPrisma.account.findFirst.mockResolvedValue({ type: 'CREDIT_CARD' });

      await expect(service.create(USER_ID, dto)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('TRANSFER işlemi oluşturur', async () => {
      const dto = {
        accountId: ACCOUNT_ID,
        transferToAccountId: 'acc-2',
        type: TransactionType.TRANSFER,
        amount: 500,
        title: 'Transfer',
      };

      mockPrisma.$transaction.mockImplementation(async (fn: any) =>
        fn({
          transaction: {
            create: jest.fn().mockResolvedValue({
              ...baseTx,
              type: TransactionType.TRANSFER,
              transferToAccountId: 'acc-2',
              transferToAccount: {
                id: 'acc-2',
                name: 'Yapı Kredi',
                icon: 'bank',
                color: '#000',
              },
              tags: [],
            }),
          },
          account: { update: jest.fn().mockResolvedValue({}) },
        }),
      );

      await service.create(USER_ID, dto);

      expect(mockEventEmitter.emit).toHaveBeenCalled();
    });
  });

  // ─── remove ──────────────────────────────────────────────────────────────────

  describe('remove()', () => {
    it('işlemi siler ve event emit eder', async () => {
      mockPrisma.transaction.findFirst.mockResolvedValue(baseTx);
      mockPrisma.$transaction.mockImplementation(async (fn: any) =>
        fn({
          account: { update: jest.fn().mockResolvedValue({}) },
          transaction: { delete: jest.fn().mockResolvedValue({}) },
        }),
      );

      const result = await service.remove(USER_ID, 'tx-1');

      expect(result).toHaveProperty('message');
      expect(mockEventEmitter.emit).toHaveBeenCalledWith(
        'transaction.deleted',
        expect.any(Object),
      );
    });

    it('bulunamazsa NotFoundException fırlatır', async () => {
      mockPrisma.transaction.findFirst.mockResolvedValue(null);

      await expect(service.remove(USER_ID, 'nonexistent')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  // ─── update ──────────────────────────────────────────────────────────────────

  describe('update()', () => {
    it('MANUAL işlemi günceller, bakiye revert+apply ve event emit eder (regresyon)', async () => {
      const manualTx = { ...baseTx, source: TransactionSource.MANUAL };
      mockPrisma.transaction.findFirst.mockResolvedValue(manualTx);
      mockPrisma.$transaction.mockImplementation(async (fn: any) =>
        fn({
          account: { update: jest.fn().mockResolvedValue({}) },
          transaction: {
            update: jest
              .fn()
              .mockResolvedValue({ ...manualTx, title: 'Güncellendi', tags: [] }),
          },
          transactionTag: {
            deleteMany: jest.fn().mockResolvedValue({}),
            createMany: jest.fn().mockResolvedValue({}),
          },
        }),
      );

      const result = await service.update(USER_ID, 'tx-1', {
        title: 'Güncellendi',
      });

      // BalanceService revert + apply çağrıldı
      expect(mockBalanceService.revert).toHaveBeenCalled();
      expect(mockBalanceService.apply).toHaveBeenCalled();

      // transaction.updated event emit edildi
      expect(mockEventEmitter.emit).toHaveBeenCalledWith(
        'transaction.updated',
        expect.any(Object),
      );
    });

    it('source=DEBT_PAYMENT ise BadRequestException fırlatır', async () => {
      const debtPaymentTx = { ...baseTx, source: TransactionSource.DEBT_PAYMENT };
      mockPrisma.transaction.findFirst.mockResolvedValue(debtPaymentTx);

      await expect(
        service.update(USER_ID, 'tx-1', { title: 'Değiştirme' }),
      ).rejects.toThrow(BadRequestException);

      await expect(
        service.update(USER_ID, 'tx-1', { title: 'Değiştirme' }),
      ).rejects.toThrow(
        'Otomatik oluşturulan işlemler düzenlenemez. Bağlı borç/abonelik kaydından yönetin.',
      );
    });

    it('source=SUBSCRIPTION ise BadRequestException fırlatır', async () => {
      const subTx = { ...baseTx, source: TransactionSource.SUBSCRIPTION };
      mockPrisma.transaction.findFirst.mockResolvedValue(subTx);

      await expect(
        service.update(USER_ID, 'tx-1', { title: 'Değiştirme' }),
      ).rejects.toThrow(BadRequestException);
    });

    it('source=RECURRING ise BadRequestException fırlatır', async () => {
      const recurringTx = { ...baseTx, source: TransactionSource.RECURRING };
      mockPrisma.transaction.findFirst.mockResolvedValue(recurringTx);

      await expect(
        service.update(USER_ID, 'tx-1', { title: 'Değiştirme' }),
      ).rejects.toThrow(BadRequestException);
    });

    it('bulunamazsa NotFoundException fırlatır', async () => {
      mockPrisma.transaction.findFirst.mockResolvedValue(null);

      await expect(service.update(USER_ID, 'nonexistent', {})).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  // ─── bulkDelete ───────────────────────────────────────────────────────────────

  describe('bulkDelete()', () => {
    const makeTx = (id: string, overrides: any = {}) => ({
      id,
      userId: USER_ID,
      accountId: ACCOUNT_ID,
      type: TransactionType.EXPENSE,
      amount: 100,
      title: `İşlem ${id}`,
      note: null,
      categoryId: 'cat-1',
      transactionDate: new Date('2026-01-15'),
      transferToAccountId: null,
      sharedBudgetId: null,
      source: TransactionSource.MANUAL,
      ...overrides,
    });

    it('3 MANUAL işlemi siler, revert 3x çağrılır, event 3x emit edilir', async () => {
      const txList = [makeTx('tx-a'), makeTx('tx-b'), makeTx('tx-c')];
      mockPrisma.transaction.findMany.mockResolvedValue(txList);

      mockPrisma.$transaction.mockImplementation(async (fn: any) =>
        fn({
          transactionTag: { deleteMany: jest.fn().mockResolvedValue({}) },
          transaction: { delete: jest.fn().mockResolvedValue({}) },
        }),
      );

      const result = await service.bulkDelete(USER_ID, { ids: ['tx-a', 'tx-b', 'tx-c'] });

      expect(result).toEqual({ deleted: 3 });
      expect(mockBalanceService.revert).toHaveBeenCalledTimes(3);
      expect(mockEventEmitter.emit).toHaveBeenCalledTimes(3);
      expect(mockEventEmitter.emit).toHaveBeenCalledWith(
        'transaction.deleted',
        expect.any(Object),
      );
    });

    it('non-MANUAL işlem içerince 400 fırlatır, $transaction çağrılmaz', async () => {
      const txList = [
        makeTx('tx-a'),
        makeTx('tx-b', { source: TransactionSource.DEBT_PAYMENT }),
      ];
      mockPrisma.transaction.findMany.mockResolvedValue(txList);

      await expect(
        service.bulkDelete(USER_ID, { ids: ['tx-a', 'tx-b'] }),
      ).rejects.toThrow(BadRequestException);

      await expect(
        service.bulkDelete(USER_ID, { ids: ['tx-a', 'tx-b'] }),
      ).rejects.toThrow('Yalnızca manuel işlemler toplu silinebilir.');

      expect(mockPrisma.$transaction).not.toHaveBeenCalled();
    });

    it('eksik/başkasına ait id varsa 400 fırlatır', async () => {
      // Sadece 1 tane geri döndü, 2 istendi
      mockPrisma.transaction.findMany.mockResolvedValue([makeTx('tx-a')]);

      await expect(
        service.bulkDelete(USER_ID, { ids: ['tx-a', 'tx-missing'] }),
      ).rejects.toThrow(BadRequestException);

      await expect(
        service.bulkDelete(USER_ID, { ids: ['tx-a', 'tx-missing'] }),
      ).rejects.toThrow('Bazı işlemler bulunamadı.');
    });
  });
});
