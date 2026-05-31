import {
  IsNumber,
  IsPositive,
  IsOptional,
  IsDateString,
} from 'class-validator';

export class PaySubscriptionDto {
  // Ödeme anında girilen gerçek tutar
  @IsNumber()
  @IsPositive()
  amount: number;

  // Ödeme tarihi; gönderilmezse bugün kabul edilir
  @IsDateString()
  @IsOptional()
  paidDate?: string;
}
