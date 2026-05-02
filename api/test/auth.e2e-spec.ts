/* eslint-disable */
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { EventEmitterModule } from '@nestjs/event-emitter';
import request from 'supertest';
import { App } from 'supertest/types';
import * as bcrypt from 'bcrypt';
import { GlobalExceptionFilter } from '../src/common/filters/http-exception.filter';
import { TransformInterceptor } from '../src/common/interceptors/transform.interceptor';
import { AuthModule } from '../src/modules/auth/auth.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { PrismaModule } from '../src/prisma/prisma.module';
import { MailService } from '../src/modules/mail/mail.service';

// ──────────────────────────────────────────────────────────────────────────────
// In-memory user store for tests
// ──────────────────────────────────────────────────────────────────────────────

const store = {
  users: {} as Record<string, any>,
  tokens: {} as Record<string, any>,
  clear() {
    this.users = {};
    this.tokens = {};
  },
};

const mockPrismaService = {
  user: {
    findUnique: jest.fn(),
    findFirst: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
  },
  passwordResetToken: {
    findUnique: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    updateMany: jest.fn(),
  },
  $transaction: jest.fn(),
  onModuleInit: jest.fn().mockResolvedValue(undefined),
  onModuleDestroy: jest.fn().mockResolvedValue(undefined),
};

function resetMocks() {
  store.clear();

  mockPrismaService.user.findUnique.mockImplementation(
    async ({ where }: any) => {
      if (where.email) return store.users[where.email] ?? null;
      if (where.id)
        return (
          Object.values(store.users).find((u: any) => u.id === where.id) ?? null
        );
      return null;
    },
  );
  mockPrismaService.user.findFirst.mockImplementation(
    async ({ where }: any) => {
      if (where.OR) {
        return (
          Object.values(store.users).find((u: any) =>
            where.OR.some(
              (c: any) =>
                (c.googleId && u.googleId === c.googleId) ||
                (c.email && u.email === c.email),
            ),
          ) ?? null
        );
      }
      return null;
    },
  );
  mockPrismaService.user.create.mockImplementation(async ({ data }: any) => {
    const user = {
      id: `user-${Date.now()}`,
      ...data,
      currency: 'TRY',
      language: 'tr',
      avatarUrl: null,
    };
    store.users[user.email] = user;
    return user;
  });
  mockPrismaService.user.update.mockImplementation(
    async ({ where, data }: any) => {
      const user = Object.values(store.users).find(
        (u: any) => u.id === where.id,
      );
      if (user) Object.assign(user, data);
      return user;
    },
  );
  mockPrismaService.passwordResetToken.updateMany.mockResolvedValue({
    count: 0,
  });
  mockPrismaService.passwordResetToken.create.mockImplementation(
    async ({ data }: any) => {
      const t = { id: `token-${Date.now()}`, ...data };
      store.tokens[data.token] = t;
      return t;
    },
  );
  mockPrismaService.passwordResetToken.findUnique.mockImplementation(
    async ({ where }: any) => store.tokens[where.token] ?? null,
  );
  mockPrismaService.passwordResetToken.update.mockImplementation(
    async ({ where, data }: any) => {
      const t = store.tokens[where.token];
      if (t) Object.assign(t, data);
      return t;
    },
  );
  mockPrismaService.$transaction.mockImplementation(async (ops: any) => {
    if (typeof ops === 'function') {
      return ops(mockPrismaService);
    }
    return Promise.all(ops.map(() => ({})));
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// Test Suite
// ──────────────────────────────────────────────────────────────────────────────

describe('Auth (e2e)', () => {
  let app: INestApplication<App>;
  let mailServiceSpy: jest.SpyInstance;

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
      ],
    })
      .overrideProvider(PrismaService)
      .useValue(mockPrismaService)
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

    // MailService'in e-posta gönderme metodunu mock'la
    try {
      const mailService = moduleFixture.get<any>('MailService', {
        strict: false,
      });
      if (mailService?.sendPasswordReset) {
        mailServiceSpy = jest
          .spyOn(mailService, 'sendPasswordReset')
          .mockResolvedValue(undefined);
      }
    } catch {
      // MailService doğrudan erişilemiyorsa jest mock yeterli
    }
  });

  afterAll(async () => {
    await app?.close();
  });

  beforeEach(() => {
    resetMocks();
  });

  // ─── POST /api/auth/register ────────────────────────────────────────────────

  describe('POST /api/auth/register', () => {
    it('yeni kullanıcı oluşturur ve 201 döner', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/auth/register')
        .send({
          fullName: 'Test Kullanıcı',
          email: 'test@example.com',
          password: 'Password123!',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('accessToken');
      expect(res.body.data).toHaveProperty('refreshToken');
      expect(res.body.data.user.email).toBe('test@example.com');
    });

    it('zaten kayıtlı e-posta 409 döner', async () => {
      const hash = await bcrypt.hash('Password123!', 10);
      store.users['dup@example.com'] = {
        id: 'u-dup',
        email: 'dup@example.com',
        fullName: 'Dup',
        passwordHash: hash,
      };

      const res = await request(app.getHttpServer())
        .post('/api/auth/register')
        .send({
          fullName: 'Test',
          email: 'dup@example.com',
          password: 'Password123!',
        });

      expect(res.status).toBe(409);
    });

    it('eksik alan ile 400 döner', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/auth/register')
        .send({ email: 'missing@example.com' });

      expect(res.status).toBe(400);
    });
  });

  // ─── POST /api/auth/login ───────────────────────────────────────────────────

  describe('POST /api/auth/login', () => {
    beforeEach(async () => {
      const hash = await bcrypt.hash('Password123!', 10);
      store.users['login@example.com'] = {
        id: 'user-login',
        email: 'login@example.com',
        fullName: 'Login User',
        passwordHash: hash,
        currency: 'TRY',
        language: 'tr',
        avatarUrl: null,
      };
    });

    it('doğru bilgilerle 200 ve token döner', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/auth/login')
        .send({ email: 'login@example.com', password: 'Password123!' });

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveProperty('accessToken');
      expect(res.body.data).toHaveProperty('refreshToken');
    });

    it('yanlış şifre 401 döner', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/auth/login')
        .send({ email: 'login@example.com', password: 'WrongPass!' });

      expect(res.status).toBe(401);
    });

    it('olmayan kullanıcı 401 döner', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/auth/login')
        .send({ email: 'ghost@example.com', password: 'Password123!' });

      expect(res.status).toBe(401);
    });
  });

  // ─── POST /api/auth/refresh ─────────────────────────────────────────────────

  describe('POST /api/auth/refresh', () => {
    it('geçerli refresh token ile yeni token alınır', async () => {
      // Kullanıcı oluştur ve login yap
      const hash = await bcrypt.hash('Password123!', 10);
      store.users['refresh@example.com'] = {
        id: 'user-refresh',
        email: 'refresh@example.com',
        fullName: 'Refresh',
        passwordHash: hash,
        currency: 'TRY',
        language: 'tr',
        avatarUrl: null,
      };

      const loginRes = await request(app.getHttpServer())
        .post('/api/auth/login')
        .send({ email: 'refresh@example.com', password: 'Password123!' });

      const { refreshToken } = loginRes.body.data;

      // RefreshTokenStrategy uses fromBodyField('refreshToken')
      const res = await request(app.getHttpServer())
        .post('/api/auth/refresh')
        .send({ refreshToken });

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveProperty('accessToken');
    });

    it('refresh token olmadan 401 döner', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/auth/refresh')
        .send({});
      expect(res.status).toBe(401);
    });
  });

  // ─── POST /api/auth/logout ──────────────────────────────────────────────────

  describe('POST /api/auth/logout', () => {
    it('token olmadan da 200 döner (stateless JWT — frontend siler)', async () => {
      const res = await request(app.getHttpServer()).post('/api/auth/logout');
      expect(res.status).toBe(200);
    });

    it('geçerli token ile 200 döner', async () => {
      const hash = await bcrypt.hash('Password123!', 10);
      store.users['logout@example.com'] = {
        id: 'user-logout',
        email: 'logout@example.com',
        fullName: 'Logout',
        passwordHash: hash,
        currency: 'TRY',
        language: 'tr',
        avatarUrl: null,
      };

      const loginRes = await request(app.getHttpServer())
        .post('/api/auth/login')
        .send({ email: 'logout@example.com', password: 'Password123!' });

      const { accessToken } = loginRes.body.data;

      const res = await request(app.getHttpServer())
        .post('/api/auth/logout')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
    });
  });

  // ─── POST /api/auth/forgot-password ─────────────────────────────────────────

  describe('POST /api/auth/forgot-password', () => {
    it('kayıtlı e-posta için 204 döner', async () => {
      store.users['forgot@example.com'] = {
        id: 'user-forgot',
        email: 'forgot@example.com',
        fullName: 'Forgot',
        passwordHash: 'hash',
      };

      const res = await request(app.getHttpServer())
        .post('/api/auth/forgot-password')
        .send({ email: 'forgot@example.com' });

      // 200 veya 204 (auth service boş resolve eder)
      expect([200, 204]).toContain(res.status);
    });

    it('olmayan e-posta için de 204 döner (güvenlik)', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/auth/forgot-password')
        .send({ email: 'ghost@example.com' });

      expect([200, 204]).toContain(res.status);
    });
  });
});
