import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ImageAnnotatorClient } from '@google-cloud/vision';

@Injectable()
export class OcrService {
  private readonly logger = new Logger(OcrService.name);
  private readonly client: ImageAnnotatorClient;

  constructor(config: ConfigService) {
    // Railway: GOOGLE_APPLICATION_CREDENTIALS_JSON (base64 veya ham JSON)
    // Local: GOOGLE_APPLICATION_CREDENTIALS (dosya yolu)
    const credentialsJson = config.get<string>('GOOGLE_APPLICATION_CREDENTIALS_JSON');

    if (credentialsJson) {
      const cleaned = credentialsJson.replace(/\s+/g, '');
      const jsonStr = cleaned.startsWith('{')
        ? credentialsJson
        : Buffer.from(cleaned, 'base64').toString('utf-8');
      const parsed = JSON.parse(jsonStr) as Record<string, string>;
      if (typeof parsed.private_key === 'string') {
        parsed.private_key = parsed.private_key.replace(/\\n/g, '\n');
      }
      this.client = new ImageAnnotatorClient({ credentials: parsed as any });
    } else {
      const keyFilename = config.get<string>('GOOGLE_APPLICATION_CREDENTIALS');
      this.client = new ImageAnnotatorClient(keyFilename ? { keyFilename } : {});
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
