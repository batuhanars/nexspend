import {
  IsString,
  IsOptional,
  MaxLength,
  IsBoolean,
  IsIn,
} from 'class-validator';

export class UpdateProfileDto {
  @IsString()
  @IsOptional()
  @MaxLength(100)
  fullName?: string;

  @IsString()
  @IsOptional()
  @IsIn(['TRY', 'USD', 'EUR', 'GBP'])
  currency?: string;

  @IsString()
  @IsOptional()
  @IsIn(['tr', 'en'])
  language?: string;

  @IsBoolean()
  @IsOptional()
  biometricEnabled?: boolean;

  @IsBoolean()
  @IsOptional()
  notificationsEnabled?: boolean;
}
