import {
  IsEnum,
  IsString,
  IsNumber,
  IsOptional,
  IsPositive,
  IsDateString,
  IsBoolean,
} from 'class-validator';
import { TransactionType, RecurrenceFrequency } from '@prisma/client';

export class UpdateRecurringTransactionDto {
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

  @IsEnum(RecurrenceFrequency)
  @IsOptional()
  frequency?: RecurrenceFrequency;

  @IsDateString()
  @IsOptional()
  endDate?: string;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}
