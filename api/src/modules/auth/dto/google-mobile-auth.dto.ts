import { IsNotEmpty, IsString } from 'class-validator';

export class GoogleMobileAuthDto {
  @IsString()
  @IsNotEmpty()
  idToken: string;
}
