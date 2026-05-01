import {
  Injectable,
  NotFoundException,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import * as bcrypt from 'bcrypt';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        fullName: true,
        email: true,
        avatarUrl: true,
        currency: true,
        language: true,
        biometricEnabled: true,
        notificationsEnabled: true,
        googleId: true,
        createdAt: true,
      },
    });

    if (!user) throw new NotFoundException('Kullanıcı bulunamadı');

    return {
      ...user,
      hasPassword: await this.hasPassword(userId),
      isGoogleLinked: !!user.googleId,
    };
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    await this.findUser(userId);

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: {
        ...(dto.fullName !== undefined && { fullName: dto.fullName }),
        ...(dto.currency !== undefined && { currency: dto.currency }),
        ...(dto.language !== undefined && { language: dto.language }),
        ...(dto.biometricEnabled !== undefined && { biometricEnabled: dto.biometricEnabled }),
        ...(dto.notificationsEnabled !== undefined && { notificationsEnabled: dto.notificationsEnabled }),
      },
      select: {
        id: true,
        fullName: true,
        email: true,
        avatarUrl: true,
        currency: true,
        language: true,
        biometricEnabled: true,
        notificationsEnabled: true,
      },
    });

    return updated;
  }

  async changePassword(userId: string, dto: ChangePasswordDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Kullanıcı bulunamadı');

    if (!user.passwordHash) {
      throw new BadRequestException(
        'Google ile giriş yapılan hesaplara şifre değiştirme uygulanamaz',
      );
    }

    const isMatch = await bcrypt.compare(dto.currentPassword, user.passwordHash);
    if (!isMatch) {
      throw new UnauthorizedException('Mevcut şifre hatalı');
    }

    if (dto.currentPassword === dto.newPassword) {
      throw new BadRequestException('Yeni şifre mevcut şifreden farklı olmalı');
    }

    const passwordHash = await bcrypt.hash(dto.newPassword, 12);
    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash },
    });

    return { message: 'Şifre güncellendi' };
  }

  async uploadAvatar(userId: string, file: Express.Multer.File) {
    const user = await this.findUser(userId);

    // Eski avatar dosyasını sil
    if (user.avatarUrl) {
      this.deleteLocalFile(user.avatarUrl);
    }

    const avatarUrl = `/uploads/avatars/${file.filename}`;
    await this.prisma.user.update({
      where: { id: userId },
      data: { avatarUrl },
    });

    return { avatarUrl };
  }

  async deleteAvatar(userId: string) {
    const user = await this.findUser(userId);

    if (!user.avatarUrl) {
      throw new BadRequestException('Profil fotoğrafı yok');
    }

    this.deleteLocalFile(user.avatarUrl);

    await this.prisma.user.update({
      where: { id: userId },
      data: { avatarUrl: null },
    });

    return { message: 'Profil fotoğrafı kaldırıldı' };
  }

  async deleteAccount(userId: string) {
    await this.findUser(userId);

    // Cascade delete Prisma schema'da tanımlı, tek sorgu yeterli
    await this.prisma.user.delete({ where: { id: userId } });

    return { message: 'Hesap silindi' };
  }

  private async findUser(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Kullanıcı bulunamadı');
    return user;
  }

  private async hasPassword(userId: string): Promise<boolean> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { passwordHash: true },
    });
    return !!(user?.passwordHash);
  }

  private deleteLocalFile(url: string) {
    try {
      const filePath = path.join(process.cwd(), url);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
    } catch {
      // Dosya silinememişse sessizce geç
    }
  }
}
