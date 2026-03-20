import { IsArray, IsBoolean, IsInt, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class UpdatePlanDefinitionDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  monthlyPrice?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  maxUsers?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  includedModules?: string[];

  @IsOptional()
  @IsNumber()
  @Min(0)
  suggestedInstallationFee?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  suggestedTrainingFee?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
