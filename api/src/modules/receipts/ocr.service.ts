import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ImageAnnotatorClient } from '@google-cloud/vision';

@Injectable()
export class OcrService {
  private readonly logger = new Logger(OcrService.name);
  private readonly client: ImageAnnotatorClient;

  constructor(config: ConfigService) {
    const keyFilename = config.get<string>('GOOGLE_APPLICATION_CREDENTIALS');
    this.client = new ImageAnnotatorClient(keyFilename ? { keyFilename } : {});
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
