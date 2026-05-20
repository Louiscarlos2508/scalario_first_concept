import { Controller, Post, Body, UseGuards, HttpStatus, HttpException } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CatalogueValidatorService } from './services/catalogue-validator.service';
import type { CatalogueType, DagValidationError } from './services/catalogue-validator.service';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { ValidateTemplateSchema } from './dto/validate-template.dto';
import type { ValidationErrorList } from './errors/validation-error.formatter';

interface ValidateResponse {
  valid: boolean;
  errors?: ValidationErrorList;
  dagErrors?: DagValidationError[];
}

@Controller('admin/templates')
@UseGuards(JwtAuthGuard)
@Roles('ADMIN_SCALARIO', 'OWNER')
export class CatalogueController {
  constructor(private readonly validator: CatalogueValidatorService) {}

  @Post('validate')
  validate(
    @Body(new ZodValidationPipe(ValidateTemplateSchema)) dto: { content: unknown; type: string },
  ): ValidateResponse {
    const result = this.validator.validateContent(dto.content, dto.type as CatalogueType);

    if (!result.valid) {
      throw new HttpException(
        { valid: false, errors: result.errors, dagErrors: result.dagErrors },
        HttpStatus.UNPROCESSABLE_ENTITY,
      );
    }

    return { valid: true };
  }
}
