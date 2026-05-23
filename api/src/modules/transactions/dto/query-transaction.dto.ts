import {
  IsEnum,
  IsOptional,
  IsString,
  IsDateString,
  IsNumber,
  Min,
} from 'class-validator';
import { TransactionType } from '@prisma/client';

export class QueryTransactionDto {
  @IsNumber()
  @Min(1)
  @IsOptional()
  page?: number = 1;

  @IsNumber()
  @Min(1)
  @IsOptional()
  limit?: number = 20;

  @IsEnum(TransactionType)
  @IsOptional()
  type?: TransactionType;

  @IsString()
  @IsOptional()
  accountId?: string;

  @IsString()
  @IsOptional()
  categoryId?: string;

  // Ortak bütçe filtresi. UUID gelirse o ortak bütçeye atanmış işlemler,
  // 'null' string'i gelirse sharedBudgetId IS NULL (yani sadece kişisel).
  @IsString()
  @IsOptional()
  sharedBudgetId?: string;

  @IsDateString()
  @IsOptional()
  startDate?: string;

  @IsDateString()
  @IsOptional()
  endDate?: string;

  @IsString()
  @IsOptional()
  search?: string;
}
