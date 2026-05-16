import {
  IsEnum,
  IsString,
  IsNumber,
  IsOptional,
  IsPositive,
  IsDateString,
  IsArray,
} from 'class-validator';
import { TransactionType } from '@prisma/client';

export class UpdateTransactionDto {
  @IsString()
  @IsOptional()
  categoryId?: string;

  @IsEnum(TransactionType)
  @IsOptional()
  type?: TransactionType;

  @IsNumber()
  @IsPositive()
  @IsOptional()
  amount?: number;

  @IsString()
  @IsOptional()
  title?: string;

  @IsString()
  @IsOptional()
  note?: string;

  @IsDateString()
  @IsOptional()
  transactionDate?: string;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  tagIds?: string[];

  // Kişisel mi ortak mı? null gönderildiğinde ortak baglanti kaldirilir.
  @IsString()
  @IsOptional()
  sharedBudgetId?: string | null;
}
