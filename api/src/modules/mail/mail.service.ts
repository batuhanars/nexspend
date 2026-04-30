import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private transporter: nodemailer.Transporter;

  constructor(private readonly configService: ConfigService) {
    this.transporter = nodemailer.createTransport({
      host: this.configService.get<string>('mail.host'),
      port: this.configService.get<number>('mail.port'),
      auth: {
        user: this.configService.get<string>('mail.user'),
        pass: this.configService.get<string>('mail.pass'),
      },
    });
  }

  async sendPasswordReset(
    to: string,
    fullName: string,
    token: string,
  ): Promise<void> {
    const frontendUrl = this.configService.get<string>('frontend.url');
    const resetUrl = `${frontendUrl}/reset-password/${token}`;
    const from = this.configService.get<string>('mail.from');

    try {
      await this.transporter.sendMail({
        from,
        to,
        subject: 'Stitch Wallet — Şifre Sıfırlama',
        html: `
          <div style="font-family: Inter, sans-serif; max-width: 480px; margin: 0 auto; background: #131313; color: #E5E2E1; padding: 32px; border-radius: 16px;">
            <h2 style="color: #BAC3FF; margin-bottom: 8px;">Şifre Sıfırlama</h2>
            <p>Merhaba <strong>${fullName}</strong>,</p>
            <p>Şifrenizi sıfırlamak için aşağıdaki butona tıklayın. Bu bağlantı <strong>1 saat</strong> geçerlidir.</p>
            <a href="${resetUrl}" style="display: inline-block; margin: 24px 0; padding: 14px 28px; background: #BAC3FF; color: #131313; border-radius: 24px; text-decoration: none; font-weight: 600;">
              Şifremi Sıfırla
            </a>
            <p style="color: #9E9E9E; font-size: 13px;">Bu isteği siz yapmadıysanız bu e-postayı görmezden gelebilirsiniz.</p>
          </div>
        `,
      });
    } catch (error) {
      this.logger.error(
        `Şifre sıfırlama e-postası gönderilemedi: ${to}`,
        error,
      );
    }
  }
}
