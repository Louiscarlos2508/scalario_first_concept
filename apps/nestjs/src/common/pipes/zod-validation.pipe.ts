/* eslint-disable @typescript-eslint/no-explicit-any */
import { BadRequestException, Injectable, PipeTransform } from '@nestjs/common';
import type { ZodTypeAny } from 'zod';
import { ValidationErrorFormatter } from '../../catalogue/errors/validation-error.formatter';

@Injectable()
export class ZodValidationPipe<T extends ZodTypeAny> implements PipeTransform<unknown, any> {
  private readonly formatter: ValidationErrorFormatter;

  constructor(
    private readonly schema: T,
    formatter?: ValidationErrorFormatter,
  ) {
    this.formatter = formatter ?? new ValidationErrorFormatter();
  }

  transform(value: unknown): any {
    const result = this.schema.safeParse(value);
    if (!result.success) {
      throw new BadRequestException({
        valid: false,
        errors: this.formatter.format(result.error),
      });
    }
    return result.data;
  }
}
