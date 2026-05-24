import { z } from 'zod';

export const PaymentInitiateBodySchema = z.object({
  amount: z.number().positive(),
  currency: z.string().length(3),
  method: z.enum(['cash', 'mobile_money', 'credit']),
  provider: z
    .enum([
      'wave',
      'orange_money',
      'orange_money_ci',
      'mtn_momo',
      'moov_money',
      'internal_cash',
      'internal_credit',
    ])
    .optional(),
  meta: z.record(z.unknown()).optional(),
});

export type PaymentInitiateBody = z.infer<typeof PaymentInitiateBodySchema>;

export const PaymentVerifyBodySchema = z.object({
  session_id: z.string().min(1),
});

export type PaymentVerifyBody = z.infer<typeof PaymentVerifyBodySchema>;
