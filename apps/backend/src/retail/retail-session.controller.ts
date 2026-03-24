import { Controller, Post, Get, Body, Param, Query, Req } from '@nestjs/common';
import { PosSessionService } from '../pos/pos-session.service';
import { RequiresModule } from '../kernel/modules/module.decorator';
import { Roles } from '../kernel/rbac/roles.decorator';

@Controller('retail/sessions')
@RequiresModule('retail')
export class RetailSessionController {
  constructor(private readonly posSessionService: PosSessionService) {}

  // AC2 — POST /retail/sessions/open
  @Post('open')
  @Roles('owner', 'commercial', 'cashier')
  async openSession(
    @Body() body: { userId?: string; tenantId: string; openingBalance: number; deviceId?: string },
    @Req() req: any,
  ) {
    const userId = req.user?.sub ?? body.userId ?? null;
    return this.posSessionService.openSession({
      userId,
      tenantId: body.tenantId,
      openingBalance: body.openingBalance,
      deviceId: body.deviceId,
    });
  }

  // AC3 — POST /retail/sessions/close/:id
  @Post('close/:id')
  @Roles('owner', 'commercial', 'cashier')
  async closeSession(
    @Param('id') id: string,
    @Body() body: { closingBalance: number; varianceExplanation?: string },
  ) {
    return this.posSessionService.closeSession(id, body.closingBalance, body.varianceExplanation);
  }

  // AC4 — GET /retail/sessions/summary/:id
  @Get('summary/:id')
  @Roles('owner', 'manager')
  async getSessionSummary(@Param('id') id: string) {
    return this.posSessionService.getSessionSummary(id);
  }

  // AC5 — GET /retail/sessions/reports
  @Get('reports')
  @Roles('owner', 'manager')
  async getSessionReports(
    @Query('tenantId') tenantId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    return this.posSessionService.getSessionReports(tenantId, from, to);
  }

  // Backoffice — GET /retail/sessions/active?tenantId=
  @Get('active')
  @Roles('owner', 'manager')
  async getActiveSessions(@Query('tenantId') tenantId: string) {
    return this.posSessionService.getActiveSessionsByTenant(tenantId);
  }
}
