import {
  IsArray,
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
}

export class ReceivePurchaseOrderDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ReceivePurchaseOrderLineDto)
  lines: ReceivePurchaseOrderLineDto[];
}
