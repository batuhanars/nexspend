import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { JwtModule } from '@nestjs/jwt';
import { ScheduleModule } from '@nestjs/schedule';
import request from 'supertest';
import { App } from 'supertest/types';
import { TransactionType } from '@prisma/client';
import { GlobalExceptionFilter } from '../src/common/filters/http-exception.filter';
import { TransformInterceptor } from '../src/common/interceptors/transform.interceptor';
import { TransactionsModule } from '../src/modules/transactions/transactions.module';
import { AuthModule } from '../src/modules/auth/auth.module';
import { PrismaModule } from '../src/prisma/prisma.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { MailService } from '../src/modules/mail/mail.service';
import * as bcrypt from 'bcrypt';

// ──────────────────────────────────────────────────────────────────────────────
// In-memory store
// ──────────────────────────────────────────────────────────────────────────────

const store = {
  users: {} as Record<string, any>,
  accounts: {} as Record<string, any>,
  transactions: {} as Record<string, any>,
  counter: 0,
  nextId: () => `id-${++store.counter}`,
  clear() {
    this.users = {};
    this.accounts = {};
    this.transactions = {};
    this.counter = 0;
  },
};

const mockPrisma = {
  user: {
    findUnique: jest.fn(),
  },
  account: {
    findFirst: jest.fn(),
    update: jest.fn(),
  },
  transaction: {
    findMany: jest.fn(),
    findFirst: jest.fn(),
    count: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
    aggregate: jest.fn(),
  },
  recurringTransaction: {
    create: jest.fn(),
    findMany: jest.fn(),
    findFirst: jest.fn(),
    update: jest.fn(),
  },
  $transaction: jest.fn(),
  onModuleInit: jest.fn().mockResolvedValue(undefined),
  onModuleDestroy: jest.fn().mockResolvedValue(undefined),
};

function resetMocks(userId: string) {
  store.clear();

  mockPrisma.user.findUnique.mockImplementation(async ({ where }: any) => {
    if (where.id) return Object.values(store.users).find((u: any) => u.id === where.id) ?? null;
    if (where.email) return store.users[where.email] ?? null;
    return null;
  });

  mockPrisma.account.findFirst.mockImplementation(async ({ where }: any) => {
    return store.accounts[where.id] ?? null;
  });

  mockPrisma.account.update.mockImplementation(async ({ where, data }: any) => {
    const acc = store.accounts[where.id];
    if (acc && data.balance) {
      if (data.balance.increment) acc.balance += data.balance.increment;
      if (data.balance.decrement) acc.balance -= data.balance.decrement;
    }
    return acc;
  });

  mockPrisma.transaction.findMany.mockImplementation(async () =>
    Object.values(store.transactions).map((t: any) => ({
      ...t,
      tags: [],
      category: null,
      account: store.accounts[t.accountId] ?? null,
      transferToAccount: null,
    })),
  );

  mockPrisma.transaction.count.mockImplementation(async () =>
    Object.values(store.transactions).length,
  );

  mockPrisma.transaction.findFirst.mockImplementation(async ({ where }: any) => {
    const tx = store.transactions[where.id];
    if (!tx || tx.userId !== where.userId) return null;
    return {
      ...tx,
      tags: [],
      category: null,
      account: store.accounts[tx.accountId] ?? null,
      transferToAccount: null,
    };
  });

  mockPrisma.transaction.aggregate.mockImplementation(async ({ where }: any) => {
    const filtered = Object.values(store.transactions).filter((t: any) => {
      if (t.userId !== where.userId) return false;
      if (where.type && t.type !== where.type) return false;
      return true;
    });
    const sum = filtered.reduce((s: number, t: any) => s + Number(t.amount), 0);
    return { _sum: { amount: sum || null } };
  });

  mockPrisma.$transaction.mockImplementation(async (fn: any) => {
    if (typeof fn === 'function') {
      const txClient = {
        transaction: {
          create: jest.fn().mockImplementation(async ({ data }: any) => {
            const tx = { id: store.nextId(), ...data, tags: [], category: null, account: null, transferToAccount: null };
            store.transactions[tx.id] = tx;
            return tx;
          }),
          update: jest.fn(),
          delete: jest.fn().mockImplementation(async ({ where }: any) => {
            const tx = store.transactions[where.id];
            delete store.transactions[where.id];
            return tx;
          }),
        },
        account: {
          update: jest.fn().mockImplementation(async ({ where, data }: any) => {
            const acc = store.accounts[where.id];
            if (acc && data.balance) {
              if (data.balance.increment) acc.balance += data.balance.increment;
              if (data.balance.decrement) acc.balance -= data.balance.decrement;
            }
            return acc;
          }),
        },
      };
      return fn(txClient);
    }
    return Promise.all(fn.map(() => ({})));
  });

  mockPrisma.recurringTransaction.create.mockResolvedValue({});
  mockPrisma.recurringTransaction.findMany.mockResolvedValue([]);
  mockPrisma.recurringTransaction.findFirst.mockResolvedValue(null);
  mockPrisma.recurringTransaction.update.mockResolvedValue({});

  // Seed a test account
  store.accounts['acc-1'] = { id: 'acc-1', name: 'Test Hesap', balance: 10000, userId };
}

// ──────────────────────────────────────────────────────────────────────────────
// Test Suite
// ──────────────────────────────────────────────────────────────────────────────

describe('Transactions (e2e)', () => {
  let app: INestApplication<App>;
  let accessToken: string;
  const userId = 'user-tx-test';
  const userEmail = 'txtest@example.com';

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({
          isGlobal: true,
          load: [
            () => ({
              jwt: {
                secret: 'e2e-tx-jwt-secret',
                refreshSecret: 'e2e-tx-jwt-refresh-secret',
                accessExpiresIn: '1h',
                refreshExpiresIn: '7d',
              },
              mail: { host: 'localhost', port: 1025, from: 'test@test.com' },
              frontend: { url: 'http://localhost:3001' },
              google: {
                clientId: 'test-client-id',
                clientSecret: 'test-client-secret',
                callbackUrl: 'http://localhost:3000/api/auth/google/callback',
              },
            }),
          ],
        }),
        EventEmitterModule.forRoot(),
        ScheduleModule.forRoot(),
        JwtModule.register({}),
        PrismaModule,
        AuthModule,
        TransactionsModule,
      ],
    })
      .overrideProvider(PrismaService)
      .useValue(mockPrisma)
      .overrideProvider(MailService)
      .useValue({ sendPasswordReset: jest.fn().mockResolvedValue(undefined) })
      .compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
        transformOptions: { enableImplicitConversion: true },
      }),
    );
    app.useGlobalFilters(new GlobalExceptionFilter());
    app.useGlobalInterceptors(new TransformInterceptor());
    await app.init();

    // Test kullanıcısı oluştur ve login yap
    const hash = await bcrypt.hash('Password123!', 10);
    const user = { id: userId, email: userEmail, fullName: 'TX Test', passwordHash: hash, currency: 'TRY', language: 'tr', avatarUrl: null };
    store.users[userEmail] = user;

    mockPrisma.user.findUnique.mockImplementation(async ({ where }: any) => {
      if (where.id) return Object.values(store.users).find((u: any) => u.id === where.id) ?? null;
      if (where.email) return store.users[where.email] ?? null;
      return null;
    });

    const loginRes = await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ email: userEmail, password: 'Password123!' });

    accessToken = loginRes.body.data.accessToken;
  });

  afterAll(async () => {
    await app?.close();
  });

  beforeEach(() => {
    resetMocks(userId);
    // Kullanıcıyı geri koy (resetMocks store'u temizler)
    const hash = '$2b$10$...(mock hash)';
    store.users[userEmail] = { id: userId, email: userEmail, fullName: 'TX Test', passwordHash: hash, currency: 'TRY', language: 'tr', avatarUrl: null };
    mockPrisma.user.findUnique.mockImplementation(async ({ where }: any) => {
      if (where.id) return Object.values(store.users).find((u: any) => u.id === where.id) ?? null;
      if (where.email) return store.users[where.email] ?? null;
      return null;
    });
  });

  // ─── GET /api/transactions ───────────────────────────────────────────────────

  describe('GET /api/transactions', () => {
    it('token olmadan 401 döner', async () => {
      const res = await request(app.getHttpServer()).get('/api/transactions');
      expect(res.status).toBe(401);
    });

    it('boş liste döner', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/transactions')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.data).toEqual([]);
      expect(res.body.data.total).toBe(0);
    });

    it('işlemler listelenince sayfalı döner', async () => {
      const txDate = new Date().toISOString();
      store.transactions['tx-1'] = {
        id: 'tx-1',
        userId,
        accountId: 'acc-1',
        type: TransactionType.EXPENSE,
        amount: 100,
        title: 'Test',
        transactionDate: txDate,
        source: 'MANUAL',
        tags: [],
      };

      const res = await request(app.getHttpServer())
        .get('/api/transactions')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.total).toBe(1);
    });
  });

  // ─── POST /api/transactions ──────────────────────────────────────────────────

  describe('POST /api/transactions', () => {
    it('EXPENSE işlemi oluşturur', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/transactions')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          accountId: 'acc-1',
          type: 'EXPENSE',
          amount: 250.50,
          title: 'Market alışverişi',
        });

      expect(res.status).toBe(201);
      expect(res.body.data.amount).toBe(250.5);
      expect(res.body.data.type).toBe('EXPENSE');
    });

    it('INCOME işlemi oluşturur', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/transactions')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          accountId: 'acc-1',
          type: 'INCOME',
          amount: 5000,
          title: 'Maaş',
        });

      expect(res.status).toBe(201);
      expect(res.body.data.type).toBe('INCOME');
    });

    it('TRANSFER için hedef hesap olmayınca 400 döner', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/transactions')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          accountId: 'acc-1',
          type: 'TRANSFER',
          amount: 500,
          title: 'Transfer',
        });

      expect(res.status).toBe(400);
    });

    it('negatif tutar 400 döner', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/transactions')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          accountId: 'acc-1',
          type: 'EXPENSE',
          amount: -100,
          title: 'Negatif',
        });

      expect(res.status).toBe(400);
    });

    it('token olmadan 401 döner', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/transactions')
        .send({ accountId: 'acc-1', type: 'EXPENSE', amount: 100, title: 'Test' });

      expect(res.status).toBe(401);
    });
  });

  // ─── GET /api/transactions/summary ──────────────────────────────────────────

  describe('GET /api/transactions/summary', () => {
    it('gelir/gider özeti döner', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/transactions/summary')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveProperty('income');
      expect(res.body.data).toHaveProperty('expense');
      expect(res.body.data).toHaveProperty('net');
    });
  });

  // ─── DELETE /api/transactions/:id ───────────────────────────────────────────

  describe('DELETE /api/transactions/:id', () => {
    it('mevcut işlemi siler', async () => {
      // Önce bir işlem oluştur
      store.transactions['del-tx-1'] = {
        id: 'del-tx-1',
        userId,
        accountId: 'acc-1',
        type: TransactionType.EXPENSE,
        amount: 50,
        title: 'Silinecek',
        transactionDate: new Date(),
        source: 'MANUAL',
        transferToAccountId: null,
      };

      mockPrisma.transaction.findFirst.mockResolvedValueOnce({
        ...store.transactions['del-tx-1'],
        tags: [],
        category: null,
        account: store.accounts['acc-1'],
        transferToAccount: null,
      });

      const res = await request(app.getHttpServer())
        .delete('/api/transactions/del-tx-1')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveProperty('message');
    });

    it('olmayan işlem 404 döner', async () => {
      mockPrisma.transaction.findFirst.mockResolvedValueOnce(null);

      const res = await request(app.getHttpServer())
        .delete('/api/transactions/nonexistent')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(404);
    });
  });
});
