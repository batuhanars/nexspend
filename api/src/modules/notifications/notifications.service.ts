import { Injectable, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  private messaging: admin.messaging.Messaging | null = null;

  constructor(private readonly prisma: PrismaService) {
    const projectId = process.env.FIREBASE_PROJECT_ID;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');

    if (projectId && clientEmail && privateKey) {
      const app = admin.initializeApp({
        credential: admin.credential.cert({ projectId, clientEmail, privateKey }),
      });
      this.messaging = admin.messaging(app);
      this.logger.log('Firebase Admin SDK başlatıldı — FCM aktif');
    } else {
      this.logger.warn(
        `Firebase ortam değişkenleri eksik — FCM devre dışı` +
          ` (PROJECT_ID=${!!projectId}, CLIENT_EMAIL=${!!clientEmail}, PRIVATE_KEY=${!!privateKey})`,
      );
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
    } catch (err: any) {
      const code = err?.errorInfo?.code as string | undefined;
      if (
        code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token'
      ) {
        await this.prisma.user.update({
          where: { id: userId },
          data: { fcmToken: null },
        });
      }
      this.logger.error(`FCM gönderilemedi [${userId}]: ${err?.message}`);
    }
  }
}
