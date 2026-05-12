import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Resend } from 'resend';

interface InviteParams {
  to: string;
  groupName: string;
  token: string;
  inviterName: string;
}

@Injectable()
export class FamilyEmailService {
  private readonly logger = new Logger(FamilyEmailService.name);
  private resend: Resend | null = null;
  private readonly from: string;
  private readonly baseUrl: string;

  constructor(private readonly config: ConfigService) {
    const apiKey = config.get<string>('RESEND_API_KEY');
    this.from = config.get<string>('RESEND_FROM_EMAIL', 'bütçe@wallet-app.com');
    this.baseUrl = config.get<string>('APP_BASE_URL', 'https://wallet-app.com');

    if (apiKey) {
      this.resend = new Resend(apiKey);
      this.logger.log('Resend e-posta servisi aktif');
    } else {
      this.logger.warn(
        'RESEND_API_KEY tanımlı değil — e-posta gönderimi devre dışı',
      );
    }
  }

  async sendInvite(params: InviteParams): Promise<void> {
    const deepLink = `wallet://invite/${params.token}`;
    const webLink = `${this.baseUrl}/invite/${params.token}`;

    if (!this.resend) {
      this.logger.log(
        `[DEV] Davet e-postası → ${params.to} | Grup: ${params.groupName} | Link: ${webLink}`,
      );
      return;
    }

    try {
      await this.resend.emails.send({
        from: this.from,
        to: [params.to],
        subject: `${params.inviterName} sizi "${params.groupName}" grubuna davet etti`,
        html: `
          <p>Merhaba,</p>
          <p><strong>${params.inviterName}</strong> sizi <strong>"${params.groupName}"</strong> ortak bütçe grubuna davet etti.</p>
          <p>
            <a href="${deepLink}" style="display:inline-block;padding:12px 24px;background:#6366f1;color:#fff;border-radius:8px;text-decoration:none;">
              Daveti Kabul Et
            </a>
          </p>
          <p>Uygulama açılmazsa: <a href="${webLink}">${webLink}</a></p>
          <p><small>Bu davet 7 gün içinde geçerliliğini yitirir.</small></p>
        `,
      });
    } catch (err) {
      this.logger.error(
        `Davet e-postası gönderilemedi (${params.to}): ${(err as Error).message}`,
      );
    }
  }
}
