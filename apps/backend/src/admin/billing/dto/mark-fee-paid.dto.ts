import { IsDateString, IsIn, IsOptional, IsString } from 'class-validator';

export class MarkFeePaidDto {
  @IsIn(['installation', 'training'])
  feeType: 'installation' | 'training';

  @IsString()
  paymentMethod: string;

  @IsOptional()
  @IsString()
  paymentRef?: string;

  @IsOptional()
  @IsDateString()
  paymentDate?: string;
}
