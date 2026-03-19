import { Controller, Get, Query, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

/**
 * GET /tenant-modules?tenantId=
 * Retourne les codes des modules actifs pour un tenant.
 * Accessible par tous les utilisateurs authentifiés (protégé par AuthGuard global).
 */
@Controller('tenant-modules')
export class TenantModulesController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async getActiveModules(@Query('tenantId') tenantId: string) {
    if (!tenantId) throw new BadRequestException('tenantId is required');

    const tenantModules = await this.prisma.tenantModule.findMany({
      where: { tenantId, status: 'active' },
      include: { module: true },
    });

    return { modules: tenantModules.map((tm) => tm.module.code) };
  }
}
