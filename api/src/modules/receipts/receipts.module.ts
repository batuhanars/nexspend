import { Module } from '@nestjs/common';
import { MulterModule } from '@nestjs/platform-express';
import { join } from 'path';
import { ReceiptsController } from './receipts.controller';
import { ReceiptsService } from './receipts.service';
import { ReceiptParserService } from './receipt-parser.service';
import { OcrService } from './ocr.service';

@Module({
  imports: [
    MulterModule.register({
      dest: join(process.cwd(), 'uploads', 'receipts'),
    }),
  ],
  controllers: [ReceiptsController],
  providers: [ReceiptsService, ReceiptParserService, OcrService],
})
export class ReceiptsModule {}
