import {
  Controller,
  Get,
  Param,
  Query,
  ForbiddenException,
  Logger,
  BadRequestException,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { BduiService } from './services/bdui.service';
import { GetLayoutParamsSchema } from './dto/get-layout.dto';
import { parseBulkScreens } from './dto/get-bulk-layouts.dto';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { CurrentTenant } from '../common/decorators/current-tenant.decorator';
import { TenantsService } from '../tenants/tenants.service';
import type { AuthenticatedUser } from '../core/auth/interfaces/jwt-payload.interface';

@ApiTags('BDUI Layouts')
@ApiBearerAuth()
@Controller('api/v1/:tenant/layout')
export class BduiController {
  private readonly logger = new Logger(BduiController.name);

  constructor(
    private readonly bduiService: BduiService,
    private readonly tenantsService: TenantsService,
  ) {}

  @Get(':screenId')
  async getLayout(
    @Param(new ZodValidationPipe(GetLayoutParamsSchema))
    params: { tenant: string; screenId: string },
    @CurrentUser() user: AuthenticatedUser,
    @CurrentTenant() tenantId: string,
  ) {
    const resolvedId = await this.resolveTenantId(params.tenant, tenantId);
    return this.bduiService.getLayout(resolvedId, params.screenId, user.roles);
  }

  @Get()
  async getBulkLayouts(
    @Param('tenant') tenant: string,
    @Query('screens') screensQuery: string,
    @CurrentUser() user: AuthenticatedUser,
    @CurrentTenant() tenantId: string,
  ) {
    const resolvedId = await this.resolveTenantId(tenant, tenantId);

    let screens: string[];
    try {
      screens = parseBulkScreens(screensQuery ?? '');
    } catch (err) {
      throw new BadRequestException({
        message: 'Validation failed',
        issues: [{ path: 'screens', message: (err as Error).message }],
      });
    }

    return this.bduiService.getBulkLayouts(resolvedId, screens, user.roles);
  }

  private async resolveTenantId(slugOrId: string, jwtTenantId: string): Promise<string> {
    if (slugOrId === jwtTenantId) return jwtTenantId;
    const resolved = await this.tenantsService.getActiveBySlug(slugOrId);
    if (!resolved || resolved !== jwtTenantId) {
      this.logger.warn(
        `Cross-tenant access denied: param=${slugOrId}, JWT tenant=${jwtTenantId}`,
      );
      throw new ForbiddenException('Cross-tenant access denied');
    }
    return resolved;
  }
}
