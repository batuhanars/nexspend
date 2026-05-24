import {
  IsArray,
  ArrayNotEmpty,
  ArrayMaxSize,
  IsString,
} from 'class-validator';

export class BulkDeleteTransactionDto {
  @IsArray()
  @ArrayNotEmpty()
  @ArrayMaxSize(100)
  @IsString({ each: true })
  ids!: string[];
}
