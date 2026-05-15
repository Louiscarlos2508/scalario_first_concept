import {
  Body,
  ConflictException,
  Controller,
  Get,
  Logger,
  NotFoundException,
  Param,
  Patch,
  UsePipes,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Roles } from '../common/decorators/roles.decorator';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { Tenant } from '../auth/entities/tenant.entity';
import { User } from '../auth/entities/user.entity';
import { RolesService } from '../security/services/roles.service';
import { SUPER_ADMIN } from '../security/constants';
import { AuditLogService } from '../audit/services/audit-log.service';
import { AUDIT_ACTIONS } from '../audit/constants';
import { RolesListSchema, UpdateRolesDto, UpdateRolesSchema } from './dto/update-roles.dto';

/**
 * GET/PATCH `/tenants/:slug/roles` — STORY-015.
 *
 * Layer 2 protected: only OWNER (of that tenant) or SUPER_ADMIN may read or
 * mutate the role list. RbacGuard enforces this; the tenant-scoping (OWNER
 * of tenant A cannot touch tenant B) will be enforced by Layer 4 RLS in
 * STORY-017 plus the slug-vs-jwt-tenant_id check performed here.
 */
@Controller('tenants')
export class TenantsRolesController {
  private readonly logger = new Logger(TenantsRolesController.name);

  constructor(
    @InjectRepository(Tenant) private readonly tenantRepo: Repository<Tenant>,
    @InjectRepository(User) private readonly userRepo: Repository<User>,
    private readonly rolesService: RolesService,
    private readonly audit: AuditLogService,
  ) {}

  @Get(':slug/roles')
  @Roles('OWNER', SUPER_ADMIN)
  async getRoles(@Param('slug') slug: string) {
    const { roles } = await this.rolesService.getRolesForTenantSlug(slug);
    return { roles };
  }

  @Patch(':slug/roles')
  @Roles('OWNER', SUPER_ADMIN)
  @UsePipes(new ZodValidationPipe(UpdateRolesSchema))
  async patchRoles(@Param('slug') slug: string, @Body() dto: UpdateRolesDto) {
    const tenant = await this.tenantRepo.findOne({ where: { slug } });
    if (!tenant) throw new NotFoundException(`Tenant ${slug} not found`);

    const current = new Set<string>(tenant.config?.roles ?? []);
    for (const r of dto.add ?? []) current.add(r);

    for (const r of dto.remove ?? []) {
      const inUse = await this.countUsersWithRole(tenant.id, r);
      if (inUse > 0) {
        const users = await this.findUsersWithRole(tenant.id, r);
        throw new ConflictException({
          message: `Role ${r} is assigned to ${inUse} active user(s); reassign before removing.`,
          role: r,
          users,
        });
      }
      current.delete(r);
    }

    const nextRoles = Array.from(current);
    const parsed = RolesListSchema.safeParse(nextRoles);
    if (!parsed.success) {
      throw new ConflictException({
        message: 'Invalid resulting role list',
        issues: parsed.error.issues.map((i) => i.message),
      });
    }

    await this.rolesService.setRolesForTenant(tenant.id, parsed.data);

    await this.audit.log({
      action: AUDIT_ACTIONS.TENANT_ROLES_PATCHED,
      tenant_id: tenant.id,
      metadata: {
        added: dto.add ?? [],
        removed: dto.remove ?? [],
        resulting: parsed.data,
      },
    });

    return { roles: parsed.data };
  }

  private async countUsersWithRole(tenant_id: string, role: string): Promise<number> {
    return this.userRepo
      .createQueryBuilder('u')
      .where('u.tenant_id = :tenant_id', { tenant_id })
      .andWhere('u.is_active = TRUE')
      .andWhere(`u.roles @> :role`, { role: JSON.stringify([role]) })
      .getCount();
  }

  private async findUsersWithRole(
    tenant_id: string,
    role: string,
  ): Promise<{ id: string; email: string }[]> {
    const rows = await this.userRepo
      .createQueryBuilder('u')
      .select(['u.id', 'u.email'])
      .where('u.tenant_id = :tenant_id', { tenant_id })
      .andWhere('u.is_active = TRUE')
      .andWhere(`u.roles @> :role`, { role: JSON.stringify([role]) })
      .limit(20)
      .getMany();
    return rows.map((u) => ({ id: u.id, email: u.email }));
  }
}
