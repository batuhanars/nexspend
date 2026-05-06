import { IsNotEmpty, IsString, Length } from 'class-validator';

export class VerifyResetCodeDto {
  @IsString()
  @IsNotEmpty()
  @Length(6, 6, { message: 'Kod 6 haneli olmalı' })
  token!: string;
}
