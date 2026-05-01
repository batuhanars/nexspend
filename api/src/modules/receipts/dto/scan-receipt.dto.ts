import { IsString, IsOptional } from 'class-validator';

export class ScanReceiptDto {
  // Flutter cihazda OCR çalıştırıp raw text gönderebilir
  @IsString()
  @IsOptional()
  rawText?: string;

  // Cihaz OCR güven skoru (0-1)
  @IsOptional()
  confidence?: number;
}
