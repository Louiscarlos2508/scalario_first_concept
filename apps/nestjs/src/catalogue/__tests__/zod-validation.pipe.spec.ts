/* eslint-disable @typescript-eslint/no-explicit-any */
import { ZodValidationPipe } from '../../common/pipes/zod-validation.pipe';
import { ValidationErrorFormatter } from '../errors/validation-error.formatter';
import { z } from 'zod';
import { BadRequestException } from '@nestjs/common';

describe('ZodValidationPipe', () => {
  it('returns parsed data for valid input', () => {
    const schema = z.object({ name: z.string(), age: z.number() });
    const pipe = new ZodValidationPipe(schema);
    const result = pipe.transform({ name: 'Alice', age: 30 });
    expect(result).toEqual({ name: 'Alice', age: 30 });
  });

  it('throws BadRequestException with FR-formatted errors for invalid input', () => {
    const schema = z.object({ name: z.string() });
    const pipe = new ZodValidationPipe(schema);

    expect(() => pipe.transform({ name: 42 })).toThrow(BadRequestException);
  });

  it('includes valid=false in error response', () => {
    const schema = z.object({ name: z.string() });
    const pipe = new ZodValidationPipe(schema);

    try {
      pipe.transform({ name: 42 });
      fail('Should have thrown');
    } catch (err) {
      expect(err).toBeInstanceOf(BadRequestException);
      const response = (err as BadRequestException).getResponse();
      expect(response).toHaveProperty('valid', false);
      expect(response).toHaveProperty('errors');
      expect((response as any).errors).toBeInstanceOf(Array);
      expect((response as any).errors.length).toBeGreaterThan(0);
    }
  });

  it('formats error path as dot-path', () => {
    const schema = z.object({ nested: z.object({ field: z.string() }) });
    const pipe = new ZodValidationPipe(schema);

    try {
      pipe.transform({ nested: { field: 123 } });
      fail('Should have thrown');
    } catch (err) {
      const response = (err as BadRequestException).getResponse() as any;
      const pathErrors = response.errors.map((e: any) => e.path);
      expect(pathErrors).toContain('.nested.field');
    }
  });

  it('uses FR messages in error output', () => {
    const schema = z.object({ layout: z.enum(['dashboard', 'list']) });
    const pipe = new ZodValidationPipe(schema);

    try {
      pipe.transform({ layout: 'invalid' });
      fail('Should have thrown');
    } catch (err) {
      const response = (err as BadRequestException).getResponse() as any;
      const enumError = response.errors.find((e: any) => e.code === 'invalid_enum_value');
      expect(enumError).toBeDefined();
      expect(enumError.message).toContain('dashboard');
    }
  });

  it('accepts custom ValidationErrorFormatter', () => {
    const schema = z.object({ name: z.string() });
    const pipe = new ZodValidationPipe(schema, new ValidationErrorFormatter());

    expect(() => pipe.transform({ name: 42 })).toThrow(BadRequestException);
  });
});
