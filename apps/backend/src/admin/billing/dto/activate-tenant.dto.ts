import { IsDateString, IsIn, IsNumber, IsOptional, IsString, Min } from 'class-validator';

const PLAN_CODES = ['free', 'standard', 'premium', 'enterprise'];

export class ActivateTenantDto {
  @IsString()
  @IsIn(PLAN_CODES)
  planCode: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  installationFee?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  trainingFee?: number;

  @IsOptional()
  @IsDateString()
  billingStartDate?: string;
}
