import { Type } from 'class-transformer';
import {
  IsDateString,
  IsNumber,
  IsString,
  IsUUID,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateSharedBudgetDto {
  @IsUUID()
  categoryId: string;

  @IsString()
  @MaxLength(100)
  name: string;

  @Type(() => Number)
  @IsNumber()
  @Min(0.01)
  amount: number;

  @IsDateString()
  startDate: string;
}
