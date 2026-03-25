import { Controller, Post, Body, Get, Query, Param, Request, ForbiddenException } from '@nestjs/common';
import { RequiresModule } from '../kernel/modules/module.decorator';
import { Roles } from '../kernel/rbac/roles.decorator';
import { PosSessionService } from './pos-session.service';

@Controller('pos/sessions')
@RequiresModule('retail')
export class PosSessionController {
    constructor(private readonly posSessionService: PosSessionService) { }

    @Post('open')
    @Roles('owner', 'commercial', 'cashier')
    async openSession(@Body() data: { userId: string; tenantId: string; openingBalance: number }) {
        return this.posSessionService.openSession(data);
    }

    @Post('close/:id')
    @Roles('owner', 'commercial', 'cashier')
    async closeSession(
        @Param('id') id: string,
        @Body() data: { closingBalance: number },
        @Request() req: any,
    ) {
        const session = await this.posSessionService.getSessionById(id);
        if (!session || session.userId !== req.user.id) {
            throw new ForbiddenException('You can only close a session you opened.');
        }
        return this.posSessionService.closeSession(id, data.closingBalance);
    }

    @Get('summary/:id')
    @Roles('manager', 'owner')
    async getSessionSummary(@Param('id') id: string) {
        return this.posSessionService.getSessionSummary(id);
    }

    @Get('active')
    @Roles('commercial', 'cashier', 'manager', 'owner')
    async getActiveSession(@Query('userId') userId: string, @Query('tenantId') tenantId: string) {
        return this.posSessionService.getActiveSession(userId, tenantId);
    }

    @Post()
    async syncSession(@Body() data: any) {
        return this.posSessionService.syncSession(data);
    }
}
