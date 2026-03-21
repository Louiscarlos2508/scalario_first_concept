import { IsDateString, IsIn, IsInt, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

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

  /** Nombre de mois payés à l'activation (1 = mensuel, 12 = annuel). Défaut : 1. */
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(24)
  months?: number;
}
