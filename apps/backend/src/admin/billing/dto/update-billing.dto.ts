import { IsBoolean, IsDecimal, IsIn, IsOptional, IsString } from 'class-validator';

const BILLING_STATUSES = ['trial', 'active', 'overdue', 'suspended'];

export class UpdateBillingDto {
  @IsOptional()
  @IsDecimal()
  installationFee?: string;

  @IsOptional()
  @IsBoolean()
  installationPaid?: boolean;

  @IsOptional()
  @IsDecimal()
  trainingFee?: string;

  @IsOptional()
  @IsBoolean()
  trainingPaid?: boolean;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsString()
  @IsIn(BILLING_STATUSES)
  billingStatus?: string;
}
