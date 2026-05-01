import {
  IsEnum,
  IsString,
  IsNumber,
  IsOptional,
  IsPositive,
  IsDateString,
} from 'class-validator';
import { TransactionType, RecurrenceFrequency } from '@prisma/client';

export class CreateRecurringTransactionDto {
  @IsString()
  accountId: string;

  @IsString()
  @IsOptional()
  categoryId?: string;

  @IsEnum(TransactionType)
  type: TransactionType;

  @IsNumber()
  @IsPositive()
  amount: number;

  @IsString()
  title: string;

  @IsString()
  @IsOptional()
  note?: string;

  @IsEnum(RecurrenceFrequency)
  frequency: RecurrenceFrequency;

  @IsDateString()
  @IsOptional()
  startDate?: string;

  @IsDateString()
  @IsOptional()
  endDate?: string;
}
