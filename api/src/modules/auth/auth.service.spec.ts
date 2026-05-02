/* eslint-disable */
import {
  ConflictException,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import * as bcrypt from 'bcrypt';

const mockPrisma = {
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
};

const mockJwt = {
  sign: jest.fn().mockReturnValue('mock-token'),
};

const mockConfig = {
  get: jest.fn().mockImplementation((key: string) => {
    const map: Record<string, string> = {
      'jwt.secret': 'test-secret',
      'jwt.refreshSecret': 'test-refresh-secret',
      'jwt.accessExpiresIn': '15m',
      'jwt.refreshExpiresIn': '7d',
    };
    return map[key];
  }),
};

const mockMail = {
  sendPasswordReset: jest.fn().mockResolvedValue(undefined),
};

describe('AuthService', () => {
  let service: AuthService;

  beforeEach(() => {
    service = new AuthService(
      mockPrisma as any,
      mockJwt as any,
      mockConfig as any,
      mockMail as any,
    );
    jest.clearAllMocks();
    mockJwt.sign.mockReturnValue('mock-token');
  });

  // ─── register ────────────────────────────────────────────────────────────────

  describe('register()', () => {
    const dto = {
      fullName: 'Test User',
      email: 'test@example.com',
      password: 'Password1!',
    };

    it('yeni kullanıcı kaydeder ve token döner', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);
      mockPrisma.user.create.mockResolvedValue({
        id: 'user-1',
        email: dto.email,
        fullName: dto.fullName,
        passwordHash: 'hash',
        currency: 'TRY',
        language: 'tr',
        avatarUrl: null,
      });

      const result = await service.register(dto);

      expect(mockPrisma.user.findUnique).toHaveBeenCalledWith({
        where: { email: dto.email },
      });
      expect(mockPrisma.user.create).toHaveBeenCalled();
      expect(result).toHaveProperty('accessToken', 'mock-token');
      expect(result.user.email).toBe(dto.email);
    });

    it('e-posta zaten kayıtlıysa ConflictException fırlatır', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({ id: 'existing' });

      await expect(service.register(dto)).rejects.toThrow(ConflictException);
    });
  });

  // ─── login ───────────────────────────────────────────────────────────────────

  describe('login()', () => {
    const dto = { email: 'test@example.com', password: 'Password1!' };

    it('doğru kimlik bilgileriyle token döner', async () => {
      const hash = await bcrypt.hash(dto.password, 10);
      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        email: dto.email,
        fullName: 'Test',
        passwordHash: hash,
        currency: 'TRY',
        language: 'tr',
        avatarUrl: null,
      });

      const result = await service.login(dto);

      expect(result).toHaveProperty('accessToken', 'mock-token');
    });

    it('kullanıcı bulunamazsa UnauthorizedException fırlatır', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);

      await expect(service.login(dto)).rejects.toThrow(UnauthorizedException);
    });

    it('şifre yanlışsa UnauthorizedException fırlatır', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        email: dto.email,
        passwordHash: await bcrypt.hash('different-password', 10),
      });

      await expect(service.login(dto)).rejects.toThrow(UnauthorizedException);
    });

    it('passwordHash yoksa UnauthorizedException fırlatır (Google hesabı)', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        email: dto.email,
        passwordHash: null,
      });

      await expect(service.login(dto)).rejects.toThrow(UnauthorizedException);
    });
  });

  // ─── refresh ─────────────────────────────────────────────────────────────────

  describe('refresh()', () => {
    it('yeni access ve refresh token üretir', () => {
      const result = service.refresh('user-1', 'test@example.com');

      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(mockJwt.sign).toHaveBeenCalledTimes(2);
    });
  });

  // ─── forgotPassword ──────────────────────────────────────────────────────────

  describe('forgotPassword()', () => {
    it('kullanıcı varsa token oluşturur ve e-posta gönderir', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        email: 'test@example.com',
        fullName: 'Test',
      });
      mockPrisma.passwordResetToken.updateMany.mockResolvedValue({ count: 0 });
      mockPrisma.passwordResetToken.create.mockResolvedValue({});

      await service.forgotPassword('test@example.com');

      expect(mockPrisma.passwordResetToken.create).toHaveBeenCalled();
      expect(mockMail.sendPasswordReset).toHaveBeenCalled();
    });

    it('kullanıcı bulunamazsa sessizce döner (güvenlik)', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);

      await expect(
        service.forgotPassword('unknown@example.com'),
      ).resolves.toBeUndefined();
      expect(mockMail.sendPasswordReset).not.toHaveBeenCalled();
    });
  });

  // ─── resetPassword ───────────────────────────────────────────────────────────

  describe('resetPassword()', () => {
    const validToken = {
      id: 'token-1',
      userId: 'user-1',
      token: 'valid-token',
      used: false,
      expiresAt: new Date(Date.now() + 3_600_000),
      user: { id: 'user-1' },
    };

    it('geçerli token ile şifreyi günceller', async () => {
      mockPrisma.passwordResetToken.findUnique.mockResolvedValue(validToken);
      mockPrisma.$transaction.mockResolvedValue([{}, {}]);

      await expect(
        service.resetPassword('valid-token', 'NewPassword1!'),
      ).resolves.toBeUndefined();
      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('token bulunamazsa BadRequestException fırlatır', async () => {
      mockPrisma.passwordResetToken.findUnique.mockResolvedValue(null);

      await expect(service.resetPassword('bad-token', 'pass')).rejects.toThrow(
        BadRequestException,
      );
    });

    it('süresi dolmuş token için BadRequestException fırlatır', async () => {
      mockPrisma.passwordResetToken.findUnique.mockResolvedValue({
        ...validToken,
        expiresAt: new Date(Date.now() - 1000),
      });

      await expect(
        service.resetPassword('expired-token', 'pass'),
      ).rejects.toThrow(BadRequestException);
    });

    it('zaten kullanılmış token için BadRequestException fırlatır', async () => {
      mockPrisma.passwordResetToken.findUnique.mockResolvedValue({
        ...validToken,
        used: true,
      });

      await expect(service.resetPassword('used-token', 'pass')).rejects.toThrow(
        BadRequestException,
      );
    });
  });

  // ─── googleAuth ──────────────────────────────────────────────────────────────

  describe('googleAuth()', () => {
    const profile = {
      id: 'google-123',
      email: 'google@example.com',
      fullName: 'Google User',
      picture: 'https://example.com/photo.jpg',
    };

    it('yeni Google kullanıcısı oluşturur', async () => {
      mockPrisma.user.findFirst.mockResolvedValue(null);
      mockPrisma.user.create.mockResolvedValue({
        id: 'user-1',
        email: profile.email,
        fullName: profile.fullName,
        currency: 'TRY',
        language: 'tr',
        avatarUrl: profile.picture,
        googleId: profile.id,
        passwordHash: '',
      });

      const result = await service.googleAuth(profile);

      expect(mockPrisma.user.create).toHaveBeenCalled();
      expect(result).toHaveProperty('accessToken');
    });

    it('mevcut kullanıcıya Google bağlar', async () => {
      const existingUser = {
        id: 'user-1',
        email: profile.email,
        fullName: 'Existing',
        currency: 'TRY',
        language: 'tr',
        avatarUrl: null,
        googleId: null,
        passwordHash: 'hash',
      };
      mockPrisma.user.findFirst.mockResolvedValue(existingUser);
      mockPrisma.user.update.mockResolvedValue({
        ...existingUser,
        googleId: profile.id,
      });

      const result = await service.googleAuth(profile);

      expect(mockPrisma.user.update).toHaveBeenCalled();
      expect(result).toHaveProperty('accessToken');
    });

    it('zaten Google bağlı kullanıcıya doğrudan token döner', async () => {
      const linkedUser = {
        id: 'user-1',
        email: profile.email,
        fullName: 'Linked',
        currency: 'TRY',
        language: 'tr',
        avatarUrl: null,
        googleId: profile.id,
        passwordHash: '',
      };
      mockPrisma.user.findFirst.mockResolvedValue(linkedUser);

      const result = await service.googleAuth(profile);

      expect(mockPrisma.user.create).not.toHaveBeenCalled();
      expect(result).toHaveProperty('accessToken');
    });
  });
});
