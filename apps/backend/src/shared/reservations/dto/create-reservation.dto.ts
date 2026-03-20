import { IsUUID, IsNumber, IsPositive, IsString, IsArray, ValidateNested, IsOptional } from 'class-validator';
import { Type } from 'class-transformer';

export class ReservationItemDto {
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
}

export class CreateReservationDto {
  @IsUUID()
  customerId: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ReservationItemDto)
  items: ReservationItemDto[];

  @IsNumber()
  @IsPositive()
  totalAmount: number;

  @IsNumber()
  @IsPositive()
  depositAmount: number;

  @IsString()
  paymentMethod: string;
}
