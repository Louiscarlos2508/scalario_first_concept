import {
  IsArray,
  IsDateString,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class ReceivePurchaseOrderLineDto {
  @IsUUID()
  purchaseOrderLineId: string;

  @IsNumber()
  @Min(0)
  @Type(() => Number)
  receivedQuantity: number;

  @IsOptional()
  @IsString()
  qualityNotes?: string;

  @IsOptional()
  @IsUUID()
  variantId?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  serialNumbers?: string[];

  @IsOptional()
  @IsDateString()
  expiresAt?: string;

  @IsOptional()
  @IsDateString()
  bestBeforeDate?: string;
}

export class ReceivePurchaseOrderDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ReceivePurchaseOrderLineDto)
  lines: ReceivePurchaseOrderLineDto[];
}
