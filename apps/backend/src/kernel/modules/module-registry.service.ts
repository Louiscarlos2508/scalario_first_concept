import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ModuleRegistryService {
  constructor(private readonly prisma: PrismaService) {}

  async isModuleActive(tenantId: string, moduleCode: string): Promise<boolean> {
    const tenantModule = await this.prisma.tenantModule.findFirst({
      where: {
        tenantId,
        status: 'active',
        module: { code: moduleCode },
      },
    });
    return tenantModule !== null;
  }

  async activateDefaultModulesForTenant(tenantId: string): Promise<void> {
    const defaultModules = await this.prisma.module.findMany({
      where: {
        OR: [{ type: 'shared' }, { code: 'retail' }],
      },
    });

    await Promise.all(
      defaultModules.map((mod) =>
        this.prisma.tenantModule.upsert({
          where: { tenantId_moduleId: { tenantId, moduleId: mod.id } },
          create: { tenantId, moduleId: mod.id, status: 'active' },
          update: { status: 'active' },
        }),
      ),
    );
  }
}
