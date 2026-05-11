import { IsNumber, IsPositive, Max } from 'class-validator';

export class ApplyInflationDto {
  @IsNumber()
  @IsPositive()
  @Max(9999999.99)
  newAmount: number;
}
