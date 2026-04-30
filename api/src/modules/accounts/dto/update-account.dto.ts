import {
  IsEnum,
  IsString,
  IsNumber,
  IsOptional,
  IsBoolean,
  Min,
  Max,
  IsPositive,
} from 'class-validator';
import { AccountType } from '@prisma/client';

export class UpdateAccountDto {
  @IsString()
  @IsOptional()
  name?: string;

  @IsEnum(AccountType)
  @IsOptional()
  type?: AccountType;

  @IsNumber()
  @IsOptional()
  balance?: number;

  @IsString()
  @IsOptional()
  currency?: string;

  @IsString()
  @IsOptional()
  icon?: string;

  @IsString()
  @IsOptional()
  color?: string;

  @IsBoolean()
  @IsOptional()
  isDefault?: boolean;

  @IsNumber()
  @IsPositive()
  @IsOptional()
  creditLimit?: number;

  @IsNumber()
  @Min(1)
  @Max(28)
  @IsOptional()
  statementDay?: number;

  @IsNumber()
  @Min(1)
  @Max(28)
  @IsOptional()
  paymentDueDay?: number;
}
