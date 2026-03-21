import {
  IsArray,
  IsDateString,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateClientOrderLineDto {
  @IsUUID()
  catalogItemId: string;

  @IsOptional()
  @IsUUID()
  variantId?: string;

  @IsNumber()
  @Min(0.001)
  @Type(() => Number)
  quantity: number;

  @IsNumber()
  @Min(0)
  @Type(() => Number)
  unitPrice: number;
}

export class CreateClientOrderDto {
  @IsString()
  @IsNotEmpty()
  tenantId: string;

  @IsUUID()
  customerId: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateClientOrderLineDto)
  lines: CreateClientOrderLineDto[];

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  depositAmount?: number;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsDateString()
  desiredDeliveryDate?: string;
}
