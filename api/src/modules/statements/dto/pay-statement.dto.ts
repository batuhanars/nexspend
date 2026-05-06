import {
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  IsUUID,
} from 'class-validator';

export class PayStatementDto {
  /** Ödenecek tutar (TRY). 0'dan büyük, ekstrenin kalan borcunu aşmamalı. */
  @IsNumber()
  @IsPositive()
  amount!: number;

  /** Ödemenin yapıldığı kaynak hesap (kredi kartı dışında bir hesap). */
  @IsUUID()
  fromAccountId!: string;

  /** Opsiyonel: ödeme tarihi (varsayılan: şimdi). */
  @IsOptional()
  @IsString()
  transactionDate?: string;
}
