import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { JwtModule, JwtService } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { EventEmitterModule } from '@nestjs/event-emitter';
import request from 'supertest';
import { App } from 'supertest/types';
import { GlobalExceptionFilter } from '../src/common/filters/http-exception.filter';
import { TransformInterceptor } from '../src/common/interceptors/transform.interceptor';
import { AuthModule } from '../src/modules/auth/auth.module';
import { PrismaModule } from '../src/prisma/prisma.module';
import * as bcrypt from 'bcrypt';

// ──────────────────────────────────────────────────────────────────────────────
// Mock Prisma
// ──────────────────────────────────────────────────────────────────────────────

const mockUsers: Record<string, any> = {};
const mockTokens: Record<string, any> = {};

const mockPrismaService = {
  user: {
    findUnique: jest.fn(async ({ where }: any) => mockUsers[where.email] ?? null),
    findFirst: jest.fn(async ({ where }: any) => {
      if (where.OR) {
        return Object.values(mockUsers).find(
          (u: any) => where.OR.some((c: any) => (c.googleId && u.googleId === c.googleId) || (c.email && u.email === c.email)),
        ) ?? null;
      }
      return null;
    }),
    create: jest.fn(async ({ data }: any) => {
      const user = { id: `user-${Date.now()}`, ...data, currency: 'TRY', language: 'tr', avatarUrl: null };
      mockUsers[user.email] = user;
      return user;
    }),
    update: jest.fn(async ({ where, data }: any) => {
      const user = Object.values(mockUsers).find((u: any) => u.id === where.id);
      if (user) Object.assign(user, data);
      return user;
    }),
  },
  passwordResetToken: {
    findUnique: jest.fn(async ({ where }: any) => mockTokens[where.token] ?? null),
    create: jest.fn(async ({ data }: any) => {
      const t = { id: `token-${Date.now()}`, ...data };
      mockTokens[data.token] = t;
      return t;
    }),
    update: jest.fn(async ({ where, data }: any) => {
      if (mockTokens[where.token]) Object.assign(mockTokens[where.token], data);
      return mockTokens[where.token];
    }),
    updateMany: jest.fn().mockResolvedValue({ count: 0 }),
  },
  $transaction: jest.fn(async (ops: any) => {
    if (typeof ops === 'function') return ops(mockPrismaService);
    return Promise.all(ops);
  }),
  onModuleInit: jest.fn(),
  onModuleDestroy: jest.fn(),
};

// ──────────────────────────────────────────────────────────────────────────────
// Test Suite
// ──────────────────────────────────────────────────────────────────────────────

describe('Auth (e2e)', () => {
  let app: INestApplication<App>;
  let accessToken: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({
          isGlobal: true,
          load: [() => ({
            jwt: {
              secret: 'e2e-test-secret',
              refreshSecret: 'e2e-test-refresh-secret',
              accessExpiresIn: '15m',
              refreshExpiresIn: '7d',
            },
            mail: { host: 'localhost', port: 1025, from: 'test@test.com' },
          })],
        }),
        EventEmitterModule.forRoot(),
        JwtModule.register({}),
        AuthModule,
      ],
    })
      .overrideProvider(PrismaModule)
      .useValue(mockPrismaService)
      .overrideProvider('PrismaService')
      .useValue(mockPrismaService)
      .compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api');
    app.useGlobalPipes(new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }));
    app.useGlobalFilters(new GlobalExceptionFilter());
    app.useGlobalInterceptors(new TransformInterceptor());

    await app.init();

    // Mail servisini mock'la
    const mailService = moduleFixture.get('MailService', { strict: false });
    if (mailService) {
      jest.spyOn(mailService, 'sendPasswordReset').mockResolvedValue(undefined as never);
    }
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    // Her test öncesi mockUsers'ı temizle
    Object.keys(mockUsers).forEach((k) => delete mockUsers[k]);
    Object.keys(mockTokens).forEach((k) => delete mockTokens[k]);
    jest.clearAllMocks();

    // Mock fonksiyonlarını yeniden bağla
    mockPrismaService.user.findUnique.mockImplementation(async ({ where }: any) => mockUsers[where.email] ?? null);
    mockPrismaService.user.create.mockImplementation(async ({ data }: any) => {
      const user = { id: `user-${Date.now()}`, ...data, currency: 'TRY', language: 'tr', avatarUrl: null };
      mockUsers[user.email] = user;
      return user;
    });
    mockPrismaService.passwordResetToken.updateMany.mockResolvedValue({ count: 0 });
    mockPrismaService.passwordResetToken.create.mockImplementation(async ({ data }: any) => {
      const t = { id: `token-${Date.now()}`, ...data };
      mockTokens[data.token] = t;
      return t;
    });
    mockPrismaService.$transaction.mockImplementation(async (ops: any) => {
      if (typeof ops === 'function') return ops(mockPrismaService);
      return Promise.all(ops.map(() => ({})));
    });
  });

  // ─── POST /api/auth/register ────────────────────────────────────────────────

  describe('POST /api/auth/register', () => {
    it('yeni kullanıcı oluşturur ve 201 döner', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/auth/register')
        .send({ fullName: 'Test Kullanıcı', email: 'test@example.com', password: 'Password123!' });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('accessToken');
      expect(res.body.data.user.email).toBe('test@example.com');

      accessToken = res.body.data.accessToken;
    });

    it('aynı e-posta ile tekrar kayıt 409 döner', async () => {
      // Önce kayıt et
      const hash = await bcrypt.hash('Password123!', 12);
      mockUsers['dup@example.com'] = { id: 'u-1', email: 'dup@example.com', passwordHash: hash };
      mockPrismaService.user.findUnique.mockImplementation(async ({ where }: any) => mockUsers[where.email] ?? null);

      const res = await request(app.getHttpServer())
        .post('/api/auth/register')
        .send({ fullName: 'Test', email: 'dup@example.com', password: 'Password123!' });

      expect(res.status).toBe(409);
    });

    it('geçersiz DTO ile 400 döner', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/auth/register')
        .send({ email: 'invalid' }); // fullName ve password eksik

      expect(res.status).toBe(400);
    });
  });

  // ─── POST /api/auth/login ───────────────────────────────────────────────────

  describe('POST /api/auth/login', () => {
    const credentials = { email: 'login@example.com', password: 'Password123!' };

    beforeEach(async () => {
      const hash = await bcrypt.hash(credentials.password, 10);
      mockUsers[credentials.email] = {
        id: 'user-login',
        email: credentials.email,
        fullName: 'Login User',
        passwordHash: hash,
        currency: 'TRY',
        language: 'tr',
        avatarUrl: null,
      };
      mockPrismaService.user.findUnique.mockImplementation(async ({ where }: any) => mockUsers[where.email] ?? null);
    });

    it('doğru bilgilerle giriş 200 döner', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/auth/login')
        .send(credentials);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveProperty('accessToken');
      expect(res.body.data).toHaveProperty('refreshToken');
    });

    it('yanlış şifre 401 döner', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/auth/login')
        .send({ email: credentials.email, password: 'WrongPass123!' });

      expect(res.status).toBe(401);
    });

    it('olmayan e-posta 401 döner', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/auth/login')
        .send({ email: 'nobody@example.com', password: 'Password123!' });

      expect(res.status).toBe(401);
    });
  });

  // ─── POST /api/auth/refresh ─────────────────────────────────────────────────

  describe('POST /api/auth/refresh', () => {
    it('geçerli refresh token ile yeni token alınır', async () => {
      // Önce giriş yap
      const hash = await bcrypt.hash('Password123!', 10);
      mockUsers['refresh@example.com'] = {
        id: 'user-refresh',
        email: 'refresh@example.com',
        fullName: 'Refresh User',
        passwordHash: hash,
        currency: 'TRY',
        language: 'tr',
        avatarUrl: null,
      };
      mockPrismaService.user.findUnique.mockImplementation(async ({ where }: any) => mockUsers[where.email] ?? null);

      const loginRes = await request(app.getHttpServer())
        .post('/api/auth/login')
        .send({ email: 'refresh@example.com', password: 'Password123!' });

      const { refreshToken } = loginRes.body.data;

      const res = await request(app.getHttpServer())
        .post('/api/auth/refresh')
        .set('Authorization', `Bearer ${refreshToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveProperty('accessToken');
    });
  });

  // ─── POST /api/auth/logout ──────────────────────────────────────────────────

  describe('POST /api/auth/logout', () => {
    it('kimlik doğrulamasız logout 401 döner', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/auth/logout');

      expect(res.status).toBe(401);
    });
  });
});
