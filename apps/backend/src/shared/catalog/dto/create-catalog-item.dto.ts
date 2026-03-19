import { IsString, IsNumber, IsOptional, IsIn, Min, IsPositive } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateCatalogItemDto {
  @IsString()
  name: string;

  @IsNumber()
  @Type(() => Number)
  price: number;

  @IsString()
  tenantId: string;

  @IsOptional()
  @IsString()
  barcode?: string;

  @IsOptional()
  @IsString()
  categoryId?: string;

  @IsOptional()
  @IsString()
  itemType?: string;

  @IsOptional()
  @IsIn(['piece', 'weight', 'volume', 'length'])
  unitType?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  pricePerUnit?: number;

  @IsOptional()
  @IsNumber()
  @IsPositive()
  @Type(() => Number)
  conversionRate?: number;
}
