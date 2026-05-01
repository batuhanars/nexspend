import { IsString, IsNumber, IsOptional, IsDateString, IsPositive } from 'class-validator';

export class UpdateReceiptDto {
  @IsNumber()
  @IsPositive()
  @IsOptional()
  parsedAmount?: number;

  @IsString()
  @IsOptional()
  parsedMerchant?: string;

  @IsDateString()
  @IsOptional()
  parsedDate?: string;

  @IsNumber()
  @IsOptional()
  parsedTax?: number;

  @IsString()
  @IsOptional()
  paymentMethod?: string;
}
