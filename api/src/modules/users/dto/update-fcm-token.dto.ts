import { IsString, IsNotEmpty, MaxLength } from 'class-validator';

export class UpdateFcmTokenDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  fcmToken: string;
}
