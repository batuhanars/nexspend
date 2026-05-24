/* eslint-disable */
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { EventEmitterModule } from '@nestjs/event-emitter';
import request from 'supertest';
import { App } from 'supertest/types';
import * as bcrypt from 'bcrypt';
import { TransactionType } from '@prisma/client';
import { GlobalExceptionFilter } from '../src/common/filters/http-exception.filter';
import { TransformInterceptor } from '../src/common/interceptors/transform.interceptor';
import { UsersModule } from '../src/modules/users/users.module';
import { AuthModule } from '../src/modules/auth/auth.module';
import { PrismaModule } from '../src/prisma/prisma.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { MailService } from '../src/modules/mail/mail.service';

// ──────────────────────────────────────────────────────────────────────────────
// In-memory store
// ──────────────────────────────────────────────────────────────────────────────

const store = {
  users: {} as Record<string, any>,
  clear() {
    this.users = {};
  },
};

const mockPrisma = {
  user: {
    findUnique: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  },
  passwordResetToken: {
    findUnique: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    updateMany: jest.fn(),
  },
  receipt: {
    findMany: jest.fn(),
    deleteMany: jest.fn(),
  },
  transaction: {
    findMany: jest.fn(),
    deleteMany: jest.fn(),
    aggregate: jest.fn(),
  },
  budget: {
    deleteMany: jest.fn(),
  },
  recurringTransaction: {
    deleteMany: jest.fn(),
  },
  subscription: {
    deleteMany: jest.fn(),
  },
  insight: {
    deleteMany: jest.fn(),
  },
  debt: {
    deleteMany: jest.fn(),
  },
  tag: {
    deleteMany: jest.fn(),
  },
  merchantCategoryMap: {
    deleteMany: jest.fn(),
  },
  account: {
    deleteMany: jest.fn(),
  },
  sharedBudget: {
    update: jest.fn(),
  },
  $transaction: jest.fn(),
  onModuleInit: jest.fn().mockResolvedValue(undefined),
  onModuleDestroy: jest.fn().mockResolvedValue(undefined),
};

function resetMocks() {
  store.clear();

  mockPrisma.user.findUnique.mockImplementation(async ({ where }: any) => {
    if (where.id)
      return (
        Object.values(store.users).find((u: any) => u.id === where.id) ?? null
      );
    if (where.email) return store.users[where.email] ?? null;
    return null;
  });
  mockPrisma.user.update.mockImplementation(async ({ where, data }: any) => {
    const user = Object.values(store.users).find(
      (u: any) => u.id === where.id,
    );
    if (user) Object.assign(user, data);
    return user;
  });
  mockPrisma.user.delete.mockImplementation(async ({ where }: any) => {
    const user = Object.values(store.users).find(
      (u: any) => u.id === where.id,
    );
    return user;
  });

  mockPrisma.passwordResetToken.updateMany.mockResolvedValue({ count: 0 });
  mockPrisma.passwordResetToken.create.mockResolvedValue({ id: 'token-1', token: 'tok' });
  mockPrisma.passwordResetToken.findUnique.mockResolvedValue(null);
  mockPrisma.passwordResetToken.update.mockResolvedValue({});

  // Reset data mocks
  mockPrisma.receipt.findMany.mockResolvedValue([]);
  mockPrisma.transaction.findMany.mockResolvedValue([]);
  mockPrisma.transaction.aggregate.mockResolvedValue({ _sum: { amount: null } });

  mockPrisma.receipt.deleteMany.mockResolvedValue({ count: 0 });
  mockPrisma.transaction.deleteMany.mockResolvedValue({ count: 0 });
  mockPrisma.budget.deleteMany.mockResolvedValue({ count: 0 });
  mockPrisma.recurringTransaction.deleteMany.mockResolvedValue({ count: 0 });
  mockPrisma.subscription.deleteMany.mockResolvedValue({ count: 0 });
  mockPrisma.insight.deleteMany.mockResolvedValue({ count: 0 });
  mockPrisma.debt.deleteMany.mockResolvedValue({ count: 0 });
  mockPrisma.tag.deleteMany.mockResolvedValue({ count: 0 });
  mockPrisma.merchantCategoryMap.deleteMany.mockResolvedValue({ count: 0 });
  mockPrisma.account.deleteMany.mockResolvedValue({ count: 0 });
  mockPrisma.sharedBudget.update.mockResolvedValue({});

  mockPrisma.$transaction.mockImplementation(async (fn: any) => {
    if (typeof fn === 'function') {
      return fn(mockPrisma);
    }
    return Promise.all(fn.map(() => ({})));
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// Test Suite
// ──────────────────────────────────────────────────────────────────────────────

describe('Users (e2e)', () => {
  let app: INestApplication<App>;
  let accessToken: string;
  const USER_ID = 'user-reset-1';

  beforeAll(async () => {
    resetMocks();

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({
          isGlobal: true,
          load: [
            () => ({
              jwt: {
                secret: 'e2e-jwt-secret',
                refreshSecret: 'e2e-jwt-refresh-secret',
                accessExpiresIn: '15m',
                refreshExpiresIn: '7d',
              },
              mail: { host: 'localhost', port: 1025, from: 'test@test.com' },
              frontend: { url: 'http://localhost:3001' },
              google: {
                clientId: 'test-google-client-id',
                clientSecret: 'test-google-client-secret',
                callbackUrl: 'http://localhost:3000/api/auth/google/callback',
              },
            }),
          ],
        }),
        EventEmitterModule.forRoot(),
        PrismaModule,
        AuthModule,
        UsersModule,
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
        forbidNonWhitelisted: true,
        transform: true,
        transformOptions: { enableImplicitConversion: true },
      }),
    );
    app.useGlobalFilters(new GlobalExceptionFilter());
    app.useGlobalInterceptors(new TransformInterceptor());

    await app.init();
  });

  afterAll(async () => {
    await app?.close();
  });

  beforeEach(async () => {
    resetMocks();

    // Kullanıcı kayıt et ve token al
    const hash = await bcrypt.hash('Password123!', 10);
    store.users['reset@example.com'] = {
      id: USER_ID,
      email: 'reset@example.com',
      fullName: 'Reset User',
      passwordHash: hash,
      currency: 'TRY',
      language: 'tr',
      avatarUrl: null,
    };

    const loginRes = await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ email: 'reset@example.com', password: 'Password123!' });

    accessToken = loginRes.body.data?.accessToken;
  });

  // ─── POST /api/users/me/reset ───────────────────────────────────────────────

  describe('POST /api/users/me/reset', () => {
    it('geçerli token ile 200 ve başarı mesajı döner', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/users/me/reset')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('message', 'Verileriniz sıfırlandı.');
    });

    it('token olmadan 401 döner', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/users/me/reset');

      expect(res.status).toBe(401);
    });

    it('geçersiz token ile 401 döner', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/users/me/reset')
        .set('Authorization', 'Bearer invalid-token-here');

      expect(res.status).toBe(401);
    });
  });
});
