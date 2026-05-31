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
import { SubscriptionPeriod, SubscriptionKind } from '@prisma/client';

export class CreateSubscriptionDto {
  @IsString()
  @MaxLength(100)
  name: string;

  // BILL için tahmini tutar; gönderilmezse 0 kabul edilir (gerçek tutar ödeme anında girilir)
  @IsNumber()
  @IsPositive()
  @IsOptional()
  amount?: number;

  @IsEnum(SubscriptionKind)
  @IsOptional()
  kind?: SubscriptionKind;

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
