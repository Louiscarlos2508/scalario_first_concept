import { IsString, IsNumber, IsPositive } from 'class-validator';

export class CompleteReservationDto {
  @IsString()
  paymentMethod: string;

  @IsNumber()
  @IsPositive()
  amount: number;
}
