import {
  Controller,
  Post,
  Body,
  Get,
  UseGuards,
  HttpCode,
  HttpStatus,
  Res,
} from '@nestjs/common';
import type { Response } from 'express';
import { ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { RefreshTokenGuard } from '../../common/guards/refresh-token.guard';
import { GoogleAuthGuard } from '../../common/guards/google-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { GoogleProfile } from './strategies/google.strategy';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly configService: ConfigService,
  ) {}

  @Post('register')
  async register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @UseGuards(RefreshTokenGuard)
  refresh(@CurrentUser() user: { id: string; email: string }) {
    return this.authService.refresh(user.id, user.email);
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  logout() {
    // Stateless JWT — frontend token'ı siler
    return { message: 'Çıkış yapıldı' };
  }

  @Post('forgot-password')
  @HttpCode(HttpStatus.OK)
  async forgotPassword(@Body() dto: ForgotPasswordDto) {
    await this.authService.forgotPassword(dto.email);
    return {
      message: 'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi',
    };
  }

  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  async resetPassword(@Body() dto: ResetPasswordDto) {
    await this.authService.resetPassword(dto.token, dto.password);
    return { message: 'Şifreniz başarıyla güncellendi' };
  }

  // Google OAuth — redirect flow
  @Get('google')
  @UseGuards(GoogleAuthGuard)
  googleAuth() {
    // Guard Google'a yönlendirir
  }

  @Get('google/callback')
  @UseGuards(GoogleAuthGuard)
  async googleCallback(
    @CurrentUser() profile: GoogleProfile,
    @Res() res: Response,
  ) {
    const result = await this.authService.googleAuth(profile);
    const frontendUrl = this.configService.get<string>('frontend.url');

    // Flutter deep link'e token'ları aktar
    const redirectUrl = `${frontendUrl}/auth/google/callback?accessToken=${result.accessToken}&refreshToken=${result.refreshToken}`;
    res.redirect(redirectUrl);
  }
}
