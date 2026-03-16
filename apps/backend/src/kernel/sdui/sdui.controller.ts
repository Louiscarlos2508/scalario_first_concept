import { Controller, Get, Query, Res } from '@nestjs/common';
import type { Response } from 'express';
import * as crypto from 'crypto';
import { SduiService } from './sdui.service';
import { CurrentTenant } from '../tenancy/tenant.decorator';

@Controller('sdui')
export class SduiController {
  constructor(private readonly sduiService: SduiService) {}

  // GET /sdui/layout?screen=pos
  @Get('layout')
  getLayout(
    @Query('screen') screen: string,
    @CurrentTenant() _tenantId: string,
    @Res() res: Response,
  ) {
    // TODO(Phase 2+): resolve businessType from tenant.business_type via TenancyService.
    // For Phase 1 all tenants are retail.
    const businessType = 'retail';

    const layout = this.sduiService.getLayout(businessType, screen);
    const etag = crypto
      .createHash('md5')
      .update(JSON.stringify(layout))
      .digest('hex');

    res.setHeader('ETag', `"${etag}"`);
    return res.json(layout);
  }
}
