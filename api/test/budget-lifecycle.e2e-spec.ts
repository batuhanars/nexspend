/* eslint-disable */
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { JwtModule } from '@nestjs/jwt';
import { ScheduleModule } from '@nestjs/schedule';
import request from 'supertest';
import { App } from 'supertest/types';
import { GlobalExceptionFilter } from '../src/common/filters/http-exception.filter';
import { TransformInterceptor } from '../src/common/interceptors/transform.interceptor';
import { BudgetsModule } from '../src/modules/budgets/budgets.module';
import { AuthModule } from '../src/modules/auth/auth.module';
import { PrismaModule } from '../src/prisma/prisma.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { MailService } from '../src/modules/mail/mail.service';
import { NotificationsModule } from '../src/modules/notifications/notifications.module';
import { NotificationsService } from '../src/modules/notifications/notifications.service';

// ──────────────────────────────────────────────────────────────────────────────
// In-memory store
// ──────────────────────────────────────────────────────────────────────────────

const store = {
  counter: 0,
  nextId: () => `id-${++store.counter}`,
};

const NOW = new Date('2026-05-21T00:00:00Z');

const makeUser = (id: string) => ({
  id,
  email: `${id}@test.com`,
  passwordHash: '$2b$10$test',
  fullName: 'Test User',
  currency: 'TRY',
  language: 'tr',
  biometricEnabled: false,
  notificationsEnabled: true,
  fcmToken: null,
  googleId: null,
  createdAt: NOW,
  updatedAt: NOW,
});

const makeCategory = (id: string) => ({
  id,
  userId: null,
  parentId: null,
  name: 'Market',
  icon: 'cart',
  color: '#aaa',
  type: 'EXPENSE',
  isSystem: true,
  sortOrder: 0,
  createdAt: NOW,
});

const makeBudget = (overrides: Partial<any> = {}) => ({
  id: store.nextId(),
  userId: 'user-1',
  categoryId: 'cat-1',
  name: 'Market Bütçesi',
  amount: 5000,
  spent: 0,
  period: 'MONTHLY',
  note: null,
  smartTracking: true,
  isActive: true,
  startDate: new Date('2026-05-01'),
  endDate: new Date('2026-05-31'),
  createdAt: NOW,
  updatedAt: NOW,
  category: makeCategory('cat-1'),
  ...overrides,
});

// ──────────────────────────────────────────────────────────────────────────────
// Mock Prisma
// ──────────────────────────────────────────────────────────────────────────────

const mockPrisma = {
  user: {
    findUnique: jest.fn(),
    findFirst: jest.fn(),
  },
  budget: {
    findMany: jest.fn(),
    findFirst: jest.fn(),
    findUnique: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  },
  sharedBudget: {
    findMany: jest.fn(),
    findFirst: jest.fn(),
    update: jest.fn(),
  },
  transaction: {
    aggregate: jest.fn(),
  },
  categoryInflationMap: {
    findUnique: jest.fn(),
  },
  inflationRate: {
    findMany: jest.fn(),
  },
  onModuleInit: jest.fn().mockResolvedValue(undefined),
  onModuleDestroy: jest.fn().mockResolvedValue(undefined),
};

function setupDefaultMocks(userId: string) {
  const user = makeUser(userId);

  mockPrisma.user.findUnique.mockImplementation(async ({ where }: any) => {
    if (where?.id === userId) return user;
    if (where?.email === user.email) return user;
    return null;
  });

  mockPrisma.budget.findFirst.mockResolvedValue(null);
  mockPrisma.budget.findMany.mockResolvedValue([]);
  mockPrisma.sharedBudget.findMany.mockResolvedValue([]);
  mockPrisma.transaction.aggregate.mockResolvedValue({ _sum: { amount: 0 } });
  mockPrisma.categoryInflationMap.findUnique.mockResolvedValue(null);
  mockPrisma.inflationRate.findMany.mockResolvedValue([]);
}

// ──────────────────────────────────────────────────────────────────────────────
// App bootstrap
// ──────────────────────────────────────────────────────────────────────────────

async function buildApp(): Promise<INestApplication> {
  const moduleFixture: TestingModule = await Test.createTestingModule({
    imports: [
      ConfigModule.forRoot({
        isGlobal: true,
        load: [
          () => ({
            jwt: {
              secret: 'test-secret',
              refreshSecret: 'e2e-budget-jwt-refresh-secret',
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
      JwtModule.register({
        global: true,
        secret: 'test-secret',
        signOptions: { expiresIn: '1d' },
      }),
      PrismaModule,
      NotificationsModule,
      AuthModule,
      BudgetsModule,
    ],
  })
    .overrideProvider(PrismaService)
    .useValue(mockPrisma)
    .overrideProvider(MailService)
    .useValue({ sendPasswordResetEmail: jest.fn() })
    .overrideProvider(NotificationsService)
    .useValue({ sendToUser: jest.fn().mockResolvedValue(undefined) })
    .compile();

  const app = moduleFixture.createNestApplication();
  app.setGlobalPrefix('api');
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  app.useGlobalFilters(new GlobalExceptionFilter());
  app.useGlobalInterceptors(new TransformInterceptor());
  await app.init();
  return app;
}

// ──────────────────────────────────────────────────────────────────────────────
// JWT token yardımcısı
// ──────────────────────────────────────────────────────────────────────────────

function makeToken(userId: string): string {
  const { JwtService } = require('@nestjs/jwt');
  const jwt = new JwtService({ secret: 'test-secret' });
  return jwt.sign({ sub: userId, email: `${userId}@test.com` });
}

// ──────────────────────────────────────────────────────────────────────────────
// Testler
// ──────────────────────────────────────────────────────────────────────────────

describe('Budget Lifecycle (e2e)', () => {
  let app: INestApplication;
  const USER_ID = 'user-e2e-1';
  let token: string;

  beforeAll(async () => {
    app = await buildApp();
    token = makeToken(USER_ID);
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    jest.clearAllMocks();
    setupDefaultMocks(USER_ID);
  });

  // ─── POST /api/budgets — endDate auto-compute ────────────────────────────────

  describe('POST /api/budgets', () => {
    it('endDate verilmezse response endDate dolu gelir (MONTHLY auto-compute)', async () => {
      const createdBudget = makeBudget({ userId: USER_ID });
      mockPrisma.budget.create.mockResolvedValue(createdBudget);
      mockPrisma.budget.update.mockResolvedValue(createdBudget);

      const res = await request(app.getHttpServer() as App)
        .post('/api/budgets')
        .set('Authorization', `Bearer ${token}`)
        .send({
          categoryId: 'cat-1',
          name: 'Market Bütçesi',
          amount: 5000,
          startDate: '2026-05-01',
          period: 'MONTHLY',
        });

      expect(res.status).toBe(201);
      // create çağrısında endDate hesaplanmış olmalı
      const createCall = mockPrisma.budget.create.mock.calls[0][0];
      expect(createCall.data.endDate).toBeInstanceOf(Date);
    });
  });

  // ─── GET /api/budgets/:id/history ────────────────────────────────────────────

  describe('GET /api/budgets/:id/history', () => {
    it('aynı kategori geçmiş kayıtlarını endDate DESC sırasıyla döner', async () => {
      const currentBudget = makeBudget({
        id: 'b-current',
        userId: USER_ID,
        startDate: new Date('2026-05-01'),
        endDate: new Date('2026-05-31'),
      });
      const olderBudget = makeBudget({
        id: 'b-older',
        userId: USER_ID,
        startDate: new Date('2026-04-01'),
        endDate: new Date('2026-04-30'),
        isActive: false,
      });

      // findOwned için findFirst
      mockPrisma.budget.findFirst.mockResolvedValueOnce(currentBudget);
      // history sorgusu için findMany
      mockPrisma.budget.findMany.mockResolvedValueOnce([olderBudget]);

      const res = await request(app.getHttpServer() as App)
        .get('/api/budgets/b-current/history')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveLength(1);
      expect(res.body.data[0].id).toBe('b-older');
    });

    it('geçmiş yok → boş dizi döner', async () => {
      const currentBudget = makeBudget({ id: 'b-new', userId: USER_ID });
      mockPrisma.budget.findFirst.mockResolvedValueOnce(currentBudget);
      mockPrisma.budget.findMany.mockResolvedValueOnce([]);

      const res = await request(app.getHttpServer() as App)
        .get('/api/budgets/b-new/history')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toEqual([]);
    });
  });

  // ─── GET /api/budgets?includeArchived=true ────────────────────────────────────

  describe('GET /api/budgets', () => {
    it('varsayılan olarak sadece aktif bütçeleri döner', async () => {
      mockPrisma.budget.findMany.mockResolvedValue([makeBudget({ userId: USER_ID })]);

      const res = await request(app.getHttpServer() as App)
        .get('/api/budgets')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(200);
      const whereArg = mockPrisma.budget.findMany.mock.calls[0][0].where;
      expect(whereArg).toHaveProperty('isActive', true);
    });

    it('includeArchived=true ile arşiv bütçeler de listede görünür', async () => {
      mockPrisma.budget.findMany.mockResolvedValue([
        makeBudget({ userId: USER_ID }),
        makeBudget({ userId: USER_ID, isActive: false }),
      ]);

      const res = await request(app.getHttpServer() as App)
        .get('/api/budgets?includeArchived=true')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(200);
      const whereArg = mockPrisma.budget.findMany.mock.calls[0][0].where;
      expect(whereArg).not.toHaveProperty('isActive');
    });
  });

  // ─── PATCH /api/budgets/:id — arşiv guard ────────────────────────────────────

  describe('PATCH /api/budgets/:id', () => {
    it('arşivlenmiş bütçeye PATCH → 400', async () => {
      const archivedBudget = makeBudget({ id: 'b-archived', userId: USER_ID, isActive: false });
      mockPrisma.budget.findFirst.mockResolvedValueOnce(archivedBudget);

      const res = await request(app.getHttpServer() as App)
        .patch('/api/budgets/b-archived')
        .set('Authorization', `Bearer ${token}`)
        .send({ amount: 6000 });

      expect(res.status).toBe(400);
      expect(res.body.message).toContain('Geçmiş döneme ait bütçe düzenlenemez');
    });
  });
});
