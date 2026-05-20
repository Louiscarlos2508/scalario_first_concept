import {
  Controller,
  Get,
  Param,
  Query,
  ForbiddenException,
  Logger,
  BadRequestException,
} from '@nestjs/common';
import { BduiService } from './services/bdui.service';
import { GetLayoutParamsSchema } from './dto/get-layout.dto';
import { parseBulkScreens } from './dto/get-bulk-layouts.dto';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { CurrentTenant } from '../common/decorators/current-tenant.decorator';
import type { AuthenticatedUser } from '../auth/interfaces/jwt-payload.interface';

@Controller(':tenant/layout')
export class BduiController {
  private readonly logger = new Logger(BduiController.name);

  constructor(private readonly bduiService: BduiService) {}

  @Get(':screenId')
  async getLayout(
    @Param(new ZodValidationPipe(GetLayoutParamsSchema))
    params: { tenant: string; screenId: string },
    @CurrentUser() user: AuthenticatedUser,
    @CurrentTenant() tenantId: string,
  ) {
    if (params.tenant !== tenantId) {
      this.logger.warn(
        `Cross-tenant access denied: param tenant=${params.tenant}, JWT tenant=${tenantId}`,
      );
      throw new ForbiddenException('Cross-tenant access denied');
    }

    return this.bduiService.getLayout(tenantId, params.screenId, user.roles);
  }

  @Get()
  async getBulkLayouts(
    @Param('tenant') tenant: string,
    @Query('screens') screensQuery: string,
    @CurrentUser() user: AuthenticatedUser,
    @CurrentTenant() tenantId: string,
  ) {
    if (tenant !== tenantId) {
      throw new ForbiddenException('Cross-tenant access denied');
    }

    let screens: string[];
    try {
      screens = parseBulkScreens(screensQuery ?? '');
    } catch (err) {
      throw new BadRequestException({
        message: 'Validation failed',
        issues: [{ path: 'screens', message: (err as Error).message }],
      });
    }

    return this.bduiService.getBulkLayouts(tenantId, screens, user.roles);
  }
}
