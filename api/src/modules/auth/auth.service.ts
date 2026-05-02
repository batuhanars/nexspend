import {
  Injectable,
  ConflictException,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';
import { MailService } from '../mail/mail.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { GoogleProfile } from './strategies/google.strategy';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';
import { addHours } from 'date-fns';
import axios from 'axios';

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

export interface AuthResponse extends AuthTokens {
  user: {
    id: string;
    email: string;
    fullName: string;
    currency: string;
    language: string;
    avatarUrl: string | null;
  };
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly mailService: MailService,
  ) {}

  async register(dto: RegisterDto): Promise<AuthResponse> {
    const existing = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (existing) {
      throw new ConflictException('Bu e-posta adresi zaten kayıtlı');
    }

    const passwordHash = await bcrypt.hash(dto.password, 12);

    const user = await this.prisma.user.create({
      data: {
        fullName: dto.fullName,
        email: dto.email,
        passwordHash,
      },
    });

    const tokens = this.generateTokens(user.id, user.email);

    return {
      ...tokens,
      user: this.sanitizeUser(user),
    };
  }

  async login(dto: LoginDto): Promise<AuthResponse> {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('E-posta veya şifre hatalı');
    }

    const isMatch = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isMatch) {
      throw new UnauthorizedException('E-posta veya şifre hatalı');
    }

    const tokens = this.generateTokens(user.id, user.email);

    return {
      ...tokens,
      user: this.sanitizeUser(user),
    };
  }

  async googleAuth(profile: GoogleProfile): Promise<AuthResponse> {
    let user = await this.prisma.user.findFirst({
      where: {
        OR: [{ googleId: profile.id }, { email: profile.email }],
      },
    });

    if (!user) {
      user = await this.prisma.user.create({
        data: {
          fullName: profile.fullName,
          email: profile.email,
          googleId: profile.id,
          avatarUrl: profile.picture ?? null,
          passwordHash: '',
        },
      });
    } else if (!user.googleId) {
      user = await this.prisma.user.update({
        where: { id: user.id },
        data: { googleId: profile.id, avatarUrl: profile.picture ?? null },
      });
    }

    const tokens = this.generateTokens(user.id, user.email);

    return {
      ...tokens,
      user: this.sanitizeUser(user),
    };
  }

  async googleMobileAuth(idToken: string): Promise<AuthResponse> {
    interface GoogleTokenPayload {
      sub: string;
      email: string;
      name?: string;
      picture?: string;
      aud?: string;
    }

    let payload: GoogleTokenPayload;
    try {
      const { data } = await axios.get<GoogleTokenPayload>(
        `https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`,
      );
      payload = data;
    } catch {
      throw new UnauthorizedException('Geçersiz Google token');
    }

    if (!payload.sub || !payload.email) {
      throw new UnauthorizedException('Geçersiz Google token');
    }

    const profile: GoogleProfile = {
      id: payload.sub,
      email: payload.email,
      fullName: payload.name ?? payload.email,
      picture: payload.picture,
    };

    return this.googleAuth(profile);
  }

  refresh(userId: string, email: string): AuthTokens {
    return this.generateTokens(userId, email);
  }

  async forgotPassword(email: string): Promise<void> {
    const user = await this.prisma.user.findUnique({ where: { email } });

    // Güvenlik: kullanıcı bulunamasa bile aynı yanıtı döndür
    if (!user) return;

    // Önceki tokenleri geçersiz kıl
    await this.prisma.passwordResetToken.updateMany({
      where: { userId: user.id, used: false },
      data: { used: true },
    });

    const token = crypto.randomBytes(32).toString('hex');
    const expiresAt = addHours(new Date(), 1);

    await this.prisma.passwordResetToken.create({
      data: {
        userId: user.id,
        token,
        expiresAt,
      },
    });

    await this.mailService.sendPasswordReset(user.email, user.fullName, token);
  }

  async resetPassword(token: string, newPassword: string): Promise<void> {
    const resetToken = await this.prisma.passwordResetToken.findUnique({
      where: { token },
      include: { user: true },
    });

    if (!resetToken || resetToken.used || resetToken.expiresAt < new Date()) {
      throw new BadRequestException('Token geçersiz veya süresi dolmuş');
    }

    const passwordHash = await bcrypt.hash(newPassword, 12);

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: resetToken.userId },
        data: { passwordHash },
      }),
      this.prisma.passwordResetToken.update({
        where: { id: resetToken.id },
        data: { used: true },
      }),
    ]);
  }

  private generateTokens(userId: string, email: string): AuthTokens {
    const payload = { sub: userId, email };
    const accessExp =
      this.configService.get<string>('jwt.accessExpiresIn') ?? '15m';
    const refreshExp =
      this.configService.get<string>('jwt.refreshExpiresIn') ?? '7d';

    const accessToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('jwt.secret'),
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      expiresIn: accessExp as any,
    });

    const refreshToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('jwt.refreshSecret'),
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      expiresIn: refreshExp as any,
    });

    return { accessToken, refreshToken };
  }

  private sanitizeUser(user: {
    id: string;
    email: string;
    fullName: string;
    currency: string;
    language: string;
    avatarUrl: string | null;
  }) {
    return {
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      currency: user.currency,
      language: user.language,
      avatarUrl: user.avatarUrl,
    };
  }
}
