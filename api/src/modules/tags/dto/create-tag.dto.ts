import { IsString, IsOptional, MaxLength, Matches } from 'class-validator';

export class CreateTagDto {
  @IsString()
  @MaxLength(50)
  name: string;

  @IsString()
  @Matches(/^#[0-9A-Fa-f]{6}$/, { message: 'color geçerli bir hex renk kodu olmalıdır (#RRGGBB)' })
  color: string;

  @IsString()
  @IsOptional()
  @MaxLength(50)
  icon?: string;
}

