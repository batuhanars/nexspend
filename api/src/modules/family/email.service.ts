import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MailService } from '../mail/mail.service';

interface InviteParams {
  to: string;
  groupName: string;
  token: string;
  inviterName: string;
}

@Injectable()
export class FamilyEmailService {
  private readonly baseUrl: string;

  constructor(
    private readonly mailService: MailService,
    private readonly config: ConfigService,
  ) {
    this.baseUrl = config.get<string>('APP_BASE_URL', 'https://wallet-app.com');
  }

  async sendInvite(params: InviteParams): Promise<void> {
    await this.mailService.sendFamilyInvite({
      ...params,
      baseUrl: this.baseUrl,
    });
  }
}
