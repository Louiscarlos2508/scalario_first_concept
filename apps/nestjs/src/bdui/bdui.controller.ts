import {
  Controller,
  Get,
  Param,
  Query,
  ForbiddenException,
  Logger,
  BadRequestException,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { BduiService } from './services/bdui.service';

@ApiTags('BDUI Layouts')
@ApiBearerAuth()
@Controller('api/v1/:tenant/layout')
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
