import { Controller, Post, Get, Body, Param, Query, Req, BadRequestException, ForbiddenException } from '@nestjs/common';
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
    @Body() body: { userId?: string; tenantId: string; openingBalance: number; deviceId?: string; uuid?: string },
    @Req() req: any,
  ) {
    const userId = req.user?.sub ?? body.userId;
    if (!userId) throw new BadRequestException('User identity required.');
    return this.posSessionService.openSession({
      userId,
      tenantId: body.tenantId,
      openingBalance: body.openingBalance,
      deviceId: body.deviceId,
      uuid: body.uuid,
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

  // Step 2 — POST /retail/sessions/validate/:id
  @Post('validate/:id')
  @Roles('owner', 'manager')
  async validateSession(
    @Param('id') id: string,
    @Body() body: { approved: boolean; note?: string },
    @Req() req: any,
  ) {
    const managerId = req.user?.sub;
    if (!managerId) throw new BadRequestException('Manager identity required.');
    return this.posSessionService.validateSession(id, managerId, body.note, body.approved);
  }

  // Step 3 — POST /retail/sessions/sign/:id
  @Post('sign/:id')
  @Roles('owner')
  async signSession(
    @Param('id') id: string,
    @Body() body: { approved: boolean; note?: string },
  ) {
    return this.posSessionService.signSession(id, body.note, body.approved);
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

  // Backoffice — GET /retail/sessions/pending?tenantId=
  @Get('pending')
  @Roles('owner', 'manager')
  async getPendingSessions(@Query('tenantId') tenantId: string) {
    return this.posSessionService.getPendingSessions(tenantId);
  }

  // Backoffice — GET /retail/sessions/active?tenantId=
  @Get('active')
  @Roles('owner', 'manager')
  async getActiveSessions(@Query('tenantId') tenantId: string) {
    return this.posSessionService.getActiveSessionsByTenant(tenantId);
  }

  // POST /retail/sessions/:id/movements — log a paid-in or paid-out
  @Post(':id/movements')
  @Roles('owner', 'commercial', 'cashier', 'manager')
  async addCashMovement(
    @Param('id') id: string,
    @Body() body: { type: 'IN' | 'OUT'; amount: number; reason: string },
    @Req() req: any,
  ) {
    const userId = req.user?.sub;
    if (!userId) throw new ForbiddenException('User identity required.');
    const session = await this.posSessionService.getSessionById(id);
    if (!session) throw new BadRequestException('Session not found.');
    return this.posSessionService.addCashMovement({
      sessionId: id,
      tenantId: session.tenantId,
      userId,
      type: body.type,
      amount: body.amount,
      reason: body.reason,
    });
  }

  // GET /retail/sessions/:id/movements
  @Get(':id/movements')
  @Roles('owner', 'manager', 'commercial', 'cashier')
  async getCashMovements(@Param('id') id: string) {
    return this.posSessionService.getCashMovements(id);
  }
}
