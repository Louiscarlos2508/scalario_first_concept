import { IsString, IsNumber, IsOptional, IsIn, Min, IsPositive, IsBoolean } from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateCatalogItemDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  price?: number;

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
  pricePerUnit?: number | null;

  @IsOptional()
  @IsNumber()
  @IsPositive()
  @Type(() => Number)
  conversionRate?: number | null;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  minStockLevel?: number | null;
}
