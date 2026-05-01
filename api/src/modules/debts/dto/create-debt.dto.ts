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
} from 'class-validator';
import { DebtType } from '@prisma/client';

export class CreateDebtDto {
  @IsString()
  personName: string;

  @IsEnum(DebtType)
  type: DebtType;

  @IsNumber()
  @IsPositive()
  totalAmount: number;

  @IsDateString()
  @IsOptional()
  dueDate?: string;

  @IsString()
  @IsOptional()
  note?: string;

  // Taksitli borç
  @IsBoolean()
  @IsOptional()
  hasInstallments?: boolean;

  @IsInt()
  @Min(2)
  @Max(360)
  @IsOptional()
  installmentCount?: number;

  @IsDateString()
  @IsOptional()
  firstInstallmentDate?: string;
}
