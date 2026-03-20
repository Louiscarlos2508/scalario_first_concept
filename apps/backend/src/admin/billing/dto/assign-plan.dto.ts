import { IsBoolean, IsOptional, IsString } from 'class-validator';

export class AssignPlanDto {
  @IsString()
  planCode: string;

  @IsOptional()
  @IsBoolean()
  confirmDowngrade?: boolean;
}
