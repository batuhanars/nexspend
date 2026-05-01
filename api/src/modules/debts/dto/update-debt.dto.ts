import {
  IsString,
  IsNumber,
  IsPositive,
  IsOptional,
  IsEnum,
  IsDateString,
} from 'class-validator';
import { DebtStatus } from '@prisma/client';

export class UpdateDebtDto {
  @IsString()
  @IsOptional()
  personName?: string;

  @IsNumber()
  @IsPositive()
  @IsOptional()
  totalAmount?: number;

  @IsEnum(DebtStatus)
  @IsOptional()
  status?: DebtStatus;

  @IsDateString()
  @IsOptional()
  dueDate?: string;

  @IsString()
  @IsOptional()
  note?: string;
}
