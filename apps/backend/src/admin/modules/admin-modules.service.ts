import {
  Injectable,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AdminModulesService {
  constructor(private readonly prisma: PrismaService) {}

  // ─── GET /admin/modules ────────────────────────────────────────────────────

  async listModules() {
    const modules = await this.prisma.module.findMany({
      orderBy: { name: 'asc' },
    });

    return modules.map((m) => ({
      id: m.id,
      code: m.code,
      name: m.name,
      type: m.type,
      dependencies: m.dependencies,
    }));
  }

  // ─── GET /admin/tenants/:tenantId/modules ──────────────────────────────────

  async listTenantModules(tenantId: string) {
    const [allModules, tenantModules] = await Promise.all([
      this.prisma.module.findMany({ orderBy: { name: 'asc' } }),
      this.prisma.tenantModule.findMany({
        where: { tenantId },
        include: { module: true },
      }),
    ]);

    // Build lookup: moduleId → { status, activatedAt }
    const activeMap = new Map(
      tenantModules.map((tm) => [tm.moduleId, { status: tm.status, activatedAt: tm.activatedAt }]),
    );

    return allModules.map((m) => {
      const tm = activeMap.get(m.id);
      return {
        moduleCode: m.code,
        name: m.name,
        type: m.type,
        dependencies: m.dependencies,
        status: tm?.status ?? 'inactive',
        activatedAt: tm?.activatedAt ?? null,
      };
    });
  }

  // ─── POST /admin/tenants/:tenantId/modules/:moduleCode/activate ────────────

  async activateModule(tenantId: string, moduleCode: string) {
    const mod = await this.prisma.module.findUnique({ where: { code: moduleCode } });
    if (!mod) {
      throw new NotFoundException(`Module "${moduleCode}" not found`);
    }

    // Check all dependencies are active for this tenant
    if (mod.dependencies.length > 0) {
      const activeTenantModules = await this.prisma.tenantModule.findMany({
        where: { tenantId, status: 'active' },
        include: { module: true },
      });

      const activeModuleCodes = new Set(activeTenantModules.map((tm) => tm.module.code));
      const missing = mod.dependencies.filter((dep) => !activeModuleCodes.has(dep));

      if (missing.length > 0) {
        throw new UnprocessableEntityException({
          error: 'MISSING_DEPENDENCY',
          missing,
        });
      }
    }

    const now = new Date();
    const result = await this.prisma.tenantModule.upsert({
      where: { tenantId_moduleId: { tenantId, moduleId: mod.id } },
      create: { tenantId, moduleId: mod.id, status: 'active', activatedAt: now },
      update: { status: 'active', activatedAt: now },
      include: { module: true },
    });

    return {
      moduleCode: result.module.code,
      status: result.status,
      activatedAt: result.activatedAt,
    };
  }

  // ─── POST /admin/tenants/:tenantId/modules/:moduleCode/deactivate ──────────

  async deactivateModule(tenantId: string, moduleCode: string) {
    const mod = await this.prisma.module.findUnique({ where: { code: moduleCode } });
    if (!mod) {
      throw new NotFoundException(`Module "${moduleCode}" not found`);
    }

    // Find active modules for this tenant that depend on moduleCode
    const activeTenantModules = await this.prisma.tenantModule.findMany({
      where: { tenantId, status: 'active' },
      include: { module: true },
    });

    const dependents = activeTenantModules
      .filter((tm) => tm.module.dependencies.includes(moduleCode))
      .map((tm) => tm.module.code);

    if (dependents.length > 0) {
      throw new UnprocessableEntityException({
        error: 'HAS_DEPENDENTS',
        dependents,
      });
    }

    const result = await this.prisma.tenantModule.upsert({
      where: { tenantId_moduleId: { tenantId, moduleId: mod.id } },
      create: { tenantId, moduleId: mod.id, status: 'inactive', activatedAt: null },
      update: { status: 'inactive', activatedAt: null },
      include: { module: true },
    });

    return {
      moduleCode: result.module.code,
      status: result.status,
    };
  }
}
