/* eslint-disable @typescript-eslint/no-explicit-any */
import { ValidationErrorFormatter } from '../errors/validation-error.formatter';
import { z } from 'zod';

describe('ValidationErrorFormatter', () => {
  let formatter: ValidationErrorFormatter;

  beforeEach(() => {
    formatter = new ValidationErrorFormatter();
  });

  it('formats invalid_type errors with FR messages', () => {
    const schema = z.object({ name: z.string() });
    const result = schema.safeParse({ name: 42 });
    if (!result.success) {
      const errors = formatter.format(result.error);
      expect(errors).toHaveLength(1);
      expect(errors[0].code).toBe('invalid_type');
      expect(errors[0].path).toBe('.name');
      expect(errors[0].message).toContain('chaîne');
      expect(errors[0].message).toContain('Reçu');
    }
  });

  it('formats too_small errors with FR messages', () => {
    const schema = z.object({ items: z.array(z.string()).min(1) });
    const result = schema.safeParse({ items: [] });
    if (!result.success) {
      const errors = formatter.format(result.error);
      expect(errors[0].code).toBe('too_small');
      expect(errors[0].message).toContain('au moins 1');
      expect(errors[0].message).toContain('élément(s)');
    }
  });

  it('formats too_big errors with FR messages', () => {
    const schema = z.object({ name: z.string().max(5) });
    const result = schema.safeParse({ name: 'toolongname' });
    if (!result.success) {
      const errors = formatter.format(result.error);
      expect(errors[0].code).toBe('too_big');
      expect(errors[0].message).toContain('au plus 5');
    }
  });

  it('formats invalid_string regex errors', () => {
    const schema = z.object({ id: z.string().regex(/^[a-z]+$/) });
    const result = schema.safeParse({ id: 'BAD' });
    if (!result.success) {
      const errors = formatter.format(result.error);
      expect(errors[0].code).toBe('invalid_string');
      expect(errors[0].message).toContain('format attendu');
    }
  });

  it('formats invalid_enum_value errors with FR messages', () => {
    const schema = z.object({ layout: z.enum(['dashboard', 'list', 'form', 'detail']) });
    const result = schema.safeParse({ layout: 'unknown' });
    if (!result.success) {
      const errors = formatter.format(result.error);
      expect(errors[0].code).toBe('invalid_enum_value');
      expect(errors[0].message).toContain('dashboard, list, form, detail');
      expect(errors[0].message).toContain('Reçu');
    }
  });

  it('formats unrecognized_keys errors', () => {
    const schema = z.object({ name: z.string() }).strict();
    const result = schema.safeParse({ name: 'test', extra: true });
    if (!result.success) {
      const errors = formatter.format(result.error);
      expect(errors[0].code).toBe('unrecognized_keys');
      expect(errors[0].message).toContain('extra');
    }
  });

  it('formats custom errors', () => {
    const schema = z.object({
      id: z.string().refine((v) => v.startsWith('wf_'), { message: "L'id doit commencer par wf_" }),
    });
    const result = schema.safeParse({ id: 'bad' });
    if (!result.success) {
      const errors = formatter.format(result.error);
      expect(errors[0].code).toBe('custom');
      expect(errors[0].message).toContain('wf_');
    }
  });

  it('returns all 3 errors for a payload with 3 distinct errors', () => {
    const schema = z.object({
      name: z.string(),
      age: z.number(),
      email: z.string().email(),
    });
    const result = schema.safeParse({
      name: 42,
      age: 'not a number',
      email: 'notanemail',
    });
    if (!result.success) {
      const errors = formatter.format(result.error);
      expect(errors.length).toBeGreaterThanOrEqual(3);
      expect(errors.map((e) => e.path)).toContain('.name');
      expect(errors.map((e) => e.path)).toContain('.age');
    }
  });

  it('formats dot-path from Zod path array', () => {
    const schema = z.object({
      zones: z.object({
        kpis: z.array(z.object({ type: z.string() })),
      }),
    });
    const result = schema.safeParse({
      zones: { kpis: [{ type: 123 }] },
    });
    if (!result.success) {
      const errors = formatter.format(result.error);
      expect(errors[0].path).toContain('.zones.kpis');
    }
  });

  it('falls back to raw message for unknown error codes', () => {
    const zodError = new z.ZodError([
      {
        code: 'unknown_code' as any,
        message: 'Custom unknown error',
        path: ['field'],
      },
    ]);
    const errors = formatter.format(zodError);
    expect(errors[0].message).toBe('Custom unknown error');
  });
});
