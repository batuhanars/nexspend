import {
  IsString,
  IsNumber,
  IsPositive,
  IsOptional,
  IsEnum,
  IsDateString,
  IsBoolean,
  IsInt,
  Min,
  Max,
  Matches,
  MaxLength,
} from 'class-validator';
import { SubscriptionPeriod } from '@prisma/client';

export class CreateSubscriptionDto {
  @IsString()
  @MaxLength(100)
  name: string;

  @IsNumber()
  @IsPositive()
  amount: number;

  @IsInt()
  @Min(0)
  @Max(30)
  @IsOptional()
  reminderDaysBefore?: number;

  @IsEnum(SubscriptionPeriod)
  @IsOptional()
  period?: SubscriptionPeriod;

  @IsString()
  @IsOptional()
  @MaxLength(50)
  icon?: string;

  @IsString()
  @IsOptional()
  @Matches(/^#[0-9A-Fa-f]{6}$/)
  color?: string;

  @IsString()
  accountId: string;

  @IsString()
  @IsOptional()
  categoryId?: string;

  @IsDateString()
  startDate: string;

  @IsDateString()
  nextRenewal: string;

  @IsBoolean()
  @IsOptional()
  autoDeduct?: boolean;
}
