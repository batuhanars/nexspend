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
    const from = this.configService.get<string>('mail.from');

    try {
      await this.transporter.sendMail({
        from,
        to,
        subject: 'Stitch Wallet — Şifre Sıfırlama Kodu',
        html: `
          <div style="font-family: Inter, sans-serif; max-width: 480px; margin: 0 auto; background: #131313; color: #E5E2E1; padding: 32px; border-radius: 16px;">
            <h2 style="color: #BAC3FF; margin-bottom: 8px;">Şifre Sıfırlama</h2>
            <p>Merhaba <strong>${fullName}</strong>,</p>
            <p>Şifrenizi sıfırlamak için aşağıdaki kodu uygulamada girin. Bu kod <strong>1 saat</strong> geçerlidir.</p>
            <div style="margin: 28px 0; text-align: center;">
              <div style="display: inline-block; padding: 20px 32px; background: #2A2A2A; border-radius: 12px; letter-spacing: 12px; font-size: 32px; font-weight: 700; color: #BAC3FF; font-family: 'Courier New', monospace;">
                ${token}
              </div>
            </div>
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
