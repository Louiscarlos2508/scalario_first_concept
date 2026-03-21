import {
  IsBoolean,
  IsDateString,
  IsDecimal,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

const PAYMENT_METHODS = ['cash', 'mobile_money', 'card', 'bank_transfer'];

export class RecordPaymentDto {
  @IsInt()
  @Min(1)
  @Max(24)
  months: number;

  @IsDecimal()
  amount: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsString()
  @IsIn(PAYMENT_METHODS)
  paymentMethod: string;

  @IsOptional()
  @IsString()
  paymentRef?: string;

  @IsOptional()
  @IsDateString()
  paymentDate?: string;

  @IsOptional()
  @IsBoolean()
  includeInstallation?: boolean;

  @IsOptional()
  @IsBoolean()
  includeTraining?: boolean;
}
