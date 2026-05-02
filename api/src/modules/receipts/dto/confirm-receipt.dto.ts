import {
  IsString,
  IsNumber,
  IsOptional,
  IsDateString,
  IsPositive,
} from 'class-validator';

export class ConfirmReceiptDto {
  @IsString()
  accountId: string;

  @IsString()
  @IsOptional()
  categoryId?: string;

  @IsNumber()
  @IsPositive()
  @IsOptional()
  amount?: number;

  @IsString()
  @IsOptional()
  merchant?: string;

  @IsDateString()
  @IsOptional()
  transactionDate?: string;

  @IsString()
  @IsOptional()
  note?: string;
}
