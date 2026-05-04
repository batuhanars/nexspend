import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ImageAnnotatorClient } from '@google-cloud/vision';

@Injectable()
export class OcrService {
  private readonly logger = new Logger(OcrService.name);
  private readonly client: ImageAnnotatorClient;

  constructor(config: ConfigService) {
    const credentialsJson = config.get<string>('GOOGLE_APPLICATION_CREDENTIALS_JSON');
    const keyFilename = config.get<string>('GOOGLE_APPLICATION_CREDENTIALS');

    if (credentialsJson) {
      try {
        const cleaned = credentialsJson.replace(/\s+/g, '');
        const jsonStr = cleaned.startsWith('{')
          ? credentialsJson
          : Buffer.from(cleaned, 'base64').toString('utf-8');
        const parsed = JSON.parse(jsonStr) as Record<string, string>;
        if (typeof parsed.private_key === 'string') {
          parsed.private_key = parsed.private_key.replace(/\\n/g, '\n');
        }
        this.client = new ImageAnnotatorClient({ credentials: parsed as any });
        this.logger.log('Cloud Vision: JSON credentials ile başlatıldı');
      } catch (err) {
        this.logger.error(`Cloud Vision credentials parse hatası: ${(err as Error).message}`);
        this.client = new ImageAnnotatorClient();
      }
    } else if (keyFilename) {
      this.client = new ImageAnnotatorClient({ keyFilename });
      this.logger.log('Cloud Vision: dosya credentials ile başlatıldı');
    } else {
      this.client = new ImageAnnotatorClient();
      this.logger.warn('Cloud Vision: credentials yok, OCR devre dışı');
    }
  }

  async extractText(imagePath: string): Promise<string> {
    try {
      const [result] = await this.client.documentTextDetection(imagePath);
      return result.fullTextAnnotation?.text ?? '';
    } catch (err) {
      this.logger.error(`Vision API hatası: ${(err as Error).message}`);
      return '';
    }
  }
}
