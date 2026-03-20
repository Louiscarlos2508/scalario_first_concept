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

  async setModuleStatus(tenantId: string, moduleCode: string, status: 'active' | 'inactive'): Promise<void> {
    const mod = await this.prisma.module.findUnique({ where: { code: moduleCode } });
    if (!mod) return;
    await this.prisma.tenantModule.upsert({
      where: { tenantId_moduleId: { tenantId, moduleId: mod.id } },
      create: { tenantId, moduleId: mod.id, status },
      update: { status },
    });
  }

  async activateDefaultModulesForTenant(tenantId: string, planCode: string): Promise<void> {
    // Resolve which modules the plan includes
    const plan = await this.prisma.planDefinition.findUnique({ where: { code: planCode } });
    const includedCodes: string[] = plan ? (plan.includedModules as string[]) : ['catalog', 'retail'];

    if (includedCodes.length === 0) return;

    const modules = await this.prisma.module.findMany({
      where: { code: { in: includedCodes } },
    });

    await Promise.all(
      modules.map((mod) =>
        this.prisma.tenantModule.upsert({
          where: { tenantId_moduleId: { tenantId, moduleId: mod.id } },
          create: { tenantId, moduleId: mod.id, status: 'active' },
          update: { status: 'active' },
        }),
      ),
    );
  }
}
