import { Controller, Post, Body, Get, Query, Param } from '@nestjs/common';
import { PosSessionService } from './pos-session.service';

@Controller('pos/sessions')
export class PosSessionController {
    constructor(private readonly posSessionService: PosSessionService) { }

    @Post('open')
    async openSession(@Body() data: { userId: string; tenantId: string; openingBalance: number }) {
        return this.posSessionService.openSession(data);
    }

    @Post('close/:id')
    async closeSession(@Param('id') id: string, @Body() data: { closingBalance: number }) {
        return this.posSessionService.closeSession(id, data.closingBalance);
    }

    @Get('summary/:id')
    async getSessionSummary(@Param('id') id: string) {
        return this.posSessionService.getSessionSummary(id);
    }

    @Get('active')
    async getActiveSession(@Query('userId') userId: string, @Query('tenantId') tenantId: string) {
        return this.posSessionService.getActiveSession(userId, tenantId);
    }

    @Post()
    async syncSession(@Body() data: any) {
        return this.posSessionService.syncSession(data);
    }
}
