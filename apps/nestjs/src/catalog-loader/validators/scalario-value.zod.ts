import { z } from 'zod';

// ──── Primitive ────
export const StringValueZod = z.object({
  type: z.literal('string'),
  value: z.string(),
  format: z.enum(['plain', 'email', 'phone', 'url', 'qr_raw']).optional(),
});

export const NumberValueZod = z.object({
  type: z.literal('number'),
  value: z.number(),
  unit: z.string().optional(),
});

export const BooleanValueZod = z.object({
  type: z.literal('boolean'),
  value: z.boolean(),
});

export const NullValueZod = z.object({ type: z.literal('null') });

// ──── Temporal ────
export const DateValueZod = z.object({
  type: z.literal('date'),
  value: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  timezone: z.string(),
});

export const DateTimeValueZod = z.object({
  type: z.literal('datetime'),
  value: z.string().datetime(),
  timezone: z.string(),
});

export const DurationValueZod = z.object({
  type: z.literal('duration'),
  value: z.number(),
  unit: z.enum(['minutes', 'hours', 'days', 'months']),
});

// ──── Financial ────
export const CurrencyValueZod = z.object({
  type: z.literal('currency'),
  amount: z.number().int(),
  currency: z.string(),
  display: z.string().optional(),
});

// ──── Media ────
export const FileValueZod = z.object({
  type: z.literal('file'),
  url: z.string(),
  filename: z.string(),
  mime_type: z.string(),
  size_bytes: z.number(),
  tenant_id: z.string(),
});

export const ImageValueZod = z.object({
  type: z.literal('image'),
  url: z.string().optional(),
  base64: z.string().optional(),
  width: z.number().optional(),
  height: z.number().optional(),
  mime_type: z.string(),
});

export const SignatureValueZod = z.object({
  type: z.literal('signature'),
  image_base64: z.string(),
  signed_at: z.string().datetime(),
  signed: z.boolean(),
  signer_name: z.string().optional(),
});

// ──── Geo ────
export const LocationValueZod = z.object({
  type: z.literal('location'),
  lat: z.number(),
  lng: z.number(),
  accuracy: z.number(),
  timestamp: z.string().datetime(),
  address: z.string().optional(),
});

// ──── Collection ────
export const ScalarioValueZod: z.ZodTypeAny = z.lazy(() =>
  z.discriminatedUnion('type', [
    StringValueZod, NumberValueZod, BooleanValueZod, NullValueZod,
    DateValueZod, DateTimeValueZod, DurationValueZod,
    CurrencyValueZod, FileValueZod, ImageValueZod, SignatureValueZod,
    LocationValueZod, ListValueZod, ObjectValueZod,
    EntityRefValueZod, ErrorValueZod, PendingValueZod,
  ]),
);

export const ListValueZod = z.object({
  type: z.literal('list'),
  items: z.array(ScalarioValueZod),
  item_type: z.string().optional(),
});

export const ObjectValueZod = z.object({
  type: z.literal('object'),
  fields: z.record(ScalarioValueZod),
  entity: z.string().optional(),
});

// ──── References ────
export const EntityRefValueZod = z.object({
  type: z.literal('entity_ref'),
  id: z.string(),
  entity: z.string(),
  label: z.string(),
  tenant_id: z.string(),
});

// ──── Special ────
export const ErrorValueZod = z.object({
  type: z.literal('error'),
  code: z.string(),
  message_key: z.string(),
  context: z.record(z.unknown()).optional(),
  engine: z.string(),
});

export const PendingValueZod = z.object({
  type: z.literal('pending'),
  operation_id: z.string(),
  engine: z.string(),
  expected_type: z.string(),
});

// ──── Type exports ────
export type StringValue = z.infer<typeof StringValueZod>;
export type NumberValue = z.infer<typeof NumberValueZod>;
export type BooleanValue = z.infer<typeof BooleanValueZod>;
export type DateValue = z.infer<typeof DateValueZod>;
export type DateTimeValue = z.infer<typeof DateTimeValueZod>;
export type DurationValue = z.infer<typeof DurationValueZod>;
export type CurrencyValue = z.infer<typeof CurrencyValueZod>;
export type FileValue = z.infer<typeof FileValueZod>;
export type ImageValue = z.infer<typeof ImageValueZod>;
export type SignatureValue = z.infer<typeof SignatureValueZod>;
export type LocationValue = z.infer<typeof LocationValueZod>;
export type ListValue = z.infer<typeof ListValueZod>;
export type ObjectValue = z.infer<typeof ObjectValueZod>;
export type EntityRefValue = z.infer<typeof EntityRefValueZod>;
export type ErrorValue = z.infer<typeof ErrorValueZod>;
export type PendingValue = z.infer<typeof PendingValueZod>;
export type ScalarioValue = z.infer<typeof ScalarioValueZod>;
