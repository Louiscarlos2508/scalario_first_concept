import { IsArray, IsInt, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class CreatePlanDefinitionDto {
  @IsString()
  code: string;

  @IsString()
  name: string;

  @IsNumber()
  @Min(0)
  monthlyPrice: number;

  @IsInt()
  @Min(1)
  maxUsers: number;

  @IsArray()
  @IsString({ each: true })
  includedModules: string[];

  @IsOptional()
  @IsNumber()
  @Min(0)
  suggestedInstallationFee?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  suggestedTrainingFee?: number;
}
