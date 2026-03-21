import { IsDateString, IsDecimal, IsIn, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

const BILLING_EVENT_TYPES = ['subscription', 'installation', 'training', 'plan_change', 'activation', 'invoice'];
const PAYMENT_METHODS = ['cash', 'mobile_money', 'card', 'bank_transfer'];

export class CreateBillingEventDto {
  @IsString()
  @IsIn(BILLING_EVENT_TYPES)
  type: string;

  @IsDecimal()
  amount: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsDateString()
  paidAt?: string;

  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @IsOptional()
  @IsString()
  @IsIn(PAYMENT_METHODS)
  paymentMethod?: string;

  @IsOptional()
  @IsString()
  paymentRef?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(24)
  monthsPaid?: number;
}
