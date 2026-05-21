import { Type } from 'class-transformer';
import {
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';
import { BudgetPeriod } from '@prisma/client';

export class UpdateSharedBudgetDto {
  @IsString()
  @MaxLength(100)
  @IsOptional()
  name?: string;

  @Type(() => Number)
  @IsNumber()
  @Min(0.01)
  @IsOptional()
  amount?: number;

  @IsEnum(BudgetPeriod)
  @IsOptional()
  period?: BudgetPeriod;

  @IsDateString()
  @IsOptional()
  endDate?: string;
}
