import { Injectable, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { PrismaService } from '../../prisma/prisma.service';

interface ServiceAccountJson {
  project_id?: string;
  client_email?: string;
  private_key?: string;
}

interface FirebaseMessagingError {
  errorInfo?: { code?: string };
  message?: string;
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  private messaging: admin.messaging.Messaging | null = null;

  constructor(private readonly prisma: PrismaService) {
    try {
      const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
      let credential: admin.credential.Credential;

      if (serviceAccountJson) {
        const jsonStr = serviceAccountJson.trim().startsWith('{')
          ? serviceAccountJson
          : Buffer.from(serviceAccountJson, 'base64').toString('utf-8');
        const parsed = JSON.parse(jsonStr) as ServiceAccountJson;
        credential = admin.credential.cert({
          projectId: parsed.project_id,
          clientEmail: parsed.client_email,
          privateKey:
            typeof parsed.private_key === 'string'
              ? parsed.private_key.replace(/\\n/g, '\n')
              : parsed.private_key,
        });
      } else {
        const projectId = process.env.FIREBASE_PROJECT_ID;
        const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
        const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(
          /\\n/g,
          '\n',
        );
        if (!projectId || !clientEmail || !privateKey) {
          this.logger.warn(
            `Firebase ortam değişkenleri eksik — FCM devre dışı` +
              ` (PROJECT_ID=${!!projectId}, CLIENT_EMAIL=${!!clientEmail}, PRIVATE_KEY=${!!privateKey})`,
          );
          return;
        }
        credential = admin.credential.cert({
          projectId,
          clientEmail,
          privateKey,
        });
      }

      const app = admin.initializeApp({ credential });
      this.messaging = admin.messaging(app);
      this.logger.log('Firebase Admin SDK başlatıldı — FCM aktif');
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      this.logger.error(`Firebase başlatılamadı: ${message}`);
    }
  }

  async sendToUser(
    userId: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<void> {
    if (!this.messaging) return;

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true, notificationsEnabled: true },
    });

    if (!user?.fcmToken || !user.notificationsEnabled) {
      this.logger.warn(
        `FCM atlandı [${userId}]: token=${!!user?.fcmToken}, enabled=${user?.notificationsEnabled}`,
      );
      return;
    }

    try {
      await this.messaging.send({
        token: user.fcmToken,
        notification: { title, body },
        android: { priority: 'high' },
        ...(data && { data }),
      });
      this.logger.log(`FCM gönderildi [${userId}]: ${title}`);
    } catch (err: unknown) {
      const fbErr = err as FirebaseMessagingError;
      const code = fbErr.errorInfo?.code;
      if (
        code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token'
      ) {
        await this.prisma.user.update({
          where: { id: userId },
          data: { fcmToken: null },
        });
      }
      const message = err instanceof Error ? err.message : String(err);
      this.logger.error(`FCM gönderilemedi [${userId}]: ${message}`);
    }
  }
}
