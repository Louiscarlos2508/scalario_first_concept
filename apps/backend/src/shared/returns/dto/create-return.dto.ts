import { IsUUID, IsNumber, IsPositive, IsString, IsIn, IsOptional } from 'class-validator';

export class CreateReturnDto {
  @IsUUID()
  @IsOptional()
  originalTxId?: string;

  @IsUUID()
  catalogItemId: string;

  @IsUUID()
  @IsOptional()
  variantId?: string;

  @IsNumber()
  @IsPositive()
  quantity: number;

  @IsNumber()
  @IsPositive()
  unitPrice: number;

  @IsString()
  @IsIn(['cash_refund', 'credit_note', 'exchange'])
  resolution: string;

  @IsString()
  @IsOptional()
  reason?: string;
}
