import { Controller, Post, Get, Patch, Body, Param, Query, Req } from '@nestjs/common';
import { ReservationsService } from './reservations.service';
import { CreateReservationDto } from './dto/create-reservation.dto';
import { CompleteReservationDto } from './dto/complete-reservation.dto';
import { CancelReservationDto } from './dto/cancel-reservation.dto';
import { Roles } from '../../kernel/rbac/roles.decorator';

@Controller('reservations')
export class ReservationsController {
  constructor(private readonly reservationsService: ReservationsService) {}

  @Post()
  async createReservation(
    @Query('tenantId') tenantId: string,
    @Query('userId') userId: string,
    @Body() dto: CreateReservationDto,
  ) {
    return this.reservationsService.createReservation(tenantId, userId, dto);
  }

  @Get('kpi')
  @Roles('owner', 'manager', 'cashier', 'commercial')
  async getKpi(@Query('tenantId') tenantId: string) {
    return this.reservationsService.getKpi(tenantId);
  }

  @Get()
  @Roles('owner', 'manager', 'cashier', 'commercial')
  async listReservations(
    @Query('tenantId') tenantId: string,
    @Query('status') status?: string,
    @Query('customerId') customerId?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.reservationsService.listReservations(tenantId, {
      status,
      customerId,
      page: page ? Number(page) : 1,
      limit: limit ? Number(limit) : 20,
    });
  }

  @Patch(':id/complete')
  async completeReservation(
    @Param('id') id: string,
    @Query('tenantId') tenantId: string,
    @Body() dto: CompleteReservationDto,
    @Req() req: any,
  ) {
    const userId = req.user?.sub ?? '';
    return this.reservationsService.completeReservation(tenantId, userId, id, dto);
  }

  @Patch(':id/cancel')
  @Roles('owner', 'manager')
  async cancelReservation(
    @Param('id') id: string,
    @Query('tenantId') tenantId: string,
    @Query('userId') userId: string,
    @Query('role') role: string,
    @Body() dto: CancelReservationDto,
  ) {
    return this.reservationsService.cancelReservation(tenantId, userId, id, dto, role);
  }
}
