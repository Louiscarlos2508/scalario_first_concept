import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ModuleRegistryService } from '../../kernel/modules/module-registry.service';
import { PlanDefinitionService } from './plan-definition.service';
import { AssignPlanDto } from './dto/assign-plan.dto';

@Injectable()
export class TenantPlanService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly planDefinition: PlanDefinitionService,
    private readonly moduleRegistry: ModuleRegistryService,
  ) {}

  async assignPlan(tenantId: string, dto: AssignPlanDto) {
    // 1. Validate plan exists and is active
    const newPlan = await this.planDefinition.findByCode(dto.planCode);
    if (!newPlan.isActive) {
      throw new NotFoundException(`Plan "${dto.planCode}" introuvable ou inactif`);
    }

    // 2. Load current tenant with member count
    const tenant = await this.prisma.tenant.findUnique({
      where: { id: tenantId },
      include: { _count: { select: { members: true } } },
    });
    if (!tenant) throw new NotFoundException(`Tenant introuvable`);

    const activeUserCount = tenant._count.members;
    if (activeUserCount > newPlan.maxUsers) {
      throw new ForbiddenException(
        `Le tenant a ${activeUserCount} utilisateurs actifs, le plan cible en autorise ${newPlan.maxUsers}. Désactivez des comptes avant de downgrader.`,
      );
    }

    // 3. Compute module delta
    const currentIncludedModules = await this._getCurrentPlanModules(tenant.plan);
    const newIncludedModules: string[] = newPlan.includedModules as string[];

    const modulesToDeactivate = currentIncludedModules.filter(
      (m) => !newIncludedModules.includes(m),
    );

    if (modulesToDeactivate.length > 0 && !dto.confirmDowngrade) {
      throw new ConflictException({
        modulesToDeactivate,
        message: 'Confirmation requise pour désactiver ces modules',
      });
    }

    // 4. Determine event type
    const isUpgrade = Number(newPlan.monthlyPrice) >= Number(await this._getCurrentPlanPrice(tenant.plan));
    const eventType = isUpgrade ? 'upgrade' : 'downgrade';
    const priceDelta = Math.abs(Number(newPlan.monthlyPrice) - Number(await this._getCurrentPlanPrice(tenant.plan)));

    // 5. Apply changes in a transaction
    const updatedTenant = await this.prisma.$transaction(async (tx) => {
      const updated = await tx.tenant.update({
        where: { id: tenantId },
        data: { plan: newPlan.code, maxUsers: newPlan.maxUsers },
      });

      // Activate new modules
      const modulesToActivate = newIncludedModules.filter(
        (m) => !currentIncludedModules.includes(m),
      );
      for (const code of modulesToActivate) {
        await this.moduleRegistry.setModuleStatus(tenantId, code, 'active');
      }

      // Deactivate removed modules (only if confirmed)
      for (const code of modulesToDeactivate) {
        await this.moduleRegistry.setModuleStatus(tenantId, code, 'inactive');
      }

      // Create billing event
      // TODO: refactor to BillingEventsService once 28-3 is done
      await (tx as any).billingEvent.create({
        data: {
          tenantId,
          type: eventType,
          amount: priceDelta,
          description: `Plan change: ${tenant.plan} → ${newPlan.code}`,
          status: 'paid',
        },
      });

      return updated;
    });

    return {
      id: updatedTenant.id,
      plan: updatedTenant.plan,
      maxUsers: updatedTenant.maxUsers,
      billingStatus: updatedTenant.billingStatus,
    };
  }

  private async _getCurrentPlanModules(planCode: string): Promise<string[]> {
    const plan = await this.prisma.planDefinition.findUnique({ where: { code: planCode } });
    if (!plan) return [];
    return plan.includedModules as string[];
  }

  private async _getCurrentPlanPrice(planCode: string): Promise<number> {
    const plan = await this.prisma.planDefinition.findUnique({ where: { code: planCode } });
    if (!plan) return 0;
    return Number(plan.monthlyPrice);
  }
}
