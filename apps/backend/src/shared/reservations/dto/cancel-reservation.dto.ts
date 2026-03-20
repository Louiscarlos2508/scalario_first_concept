import { IsString, IsIn } from 'class-validator';

export class CancelReservationDto {
  @IsString()
  @IsIn(['credit_note', 'cash_refund'])
  depositResolution: 'credit_note' | 'cash_refund';
}
