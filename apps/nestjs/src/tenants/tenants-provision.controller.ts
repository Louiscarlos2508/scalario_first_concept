import {
  Body,
  ConflictException,
  Controller,
  HttpCode,
  HttpStatus,
  Logger,
  Post,
  UsePipes,
} from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { Roles } from '../common/decorators/roles.decorator';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { AuthService } from '../auth/auth.service';
import { Tenant } from '../auth/entities/tenant.entity';
import { User } from '../auth/entities/user.entity';
import { SUPER_ADMIN } from '../security/constants';
import { loadTemplateRoles } from '../catalogue/templates.loader';
import { AuditLogService } from '../audit/services/audit-log.service';
import { AUDIT_ACTIONS } from '../audit/constants';
import { ProvisionTenantDto, ProvisionTenantSchema } from './dto/provision.dto';

/**
 * POST /tenants/provision — bootstrap a tenant with its first OWNER.
 * Protected by Layer 2 RBAC: only SUPER_ADMIN (STORY-015 AC-18).
 * FR-009: full transaction under 30 s (bcrypt cost 12 dominates).
 */
@Controller('tenants')
export class TenantsProvisionController {
  private readonly logger = new Logger(TenantsProvisionController.name);

  constructor(
    @InjectDataSource() private readonly ds: DataSource,
    private readonly audit: AuditLogService,
  ) {}

  @Roles(SUPER_ADMIN)
  @Post('provision')
  @HttpCode(HttpStatus.CREATED)
  @UsePipes(new ZodValidationPipe(ProvisionTenantSchema))
  async provision(@Body() dto: ProvisionTenantDto) {
    const password_hash = await AuthService.hashPassword(dto.owner_password);

    const templateRoles = dto.template ? loadTemplateRoles(dto.template) : ['OWNER'];
    if (!templateRoles.includes('OWNER')) templateRoles.unshift('OWNER');

    return this.ds.transaction(async (m) => {
      const tenantRepo = m.getRepository(Tenant);
      const userRepo = m.getRepository(User);

      const existing = await tenantRepo.findOne({ where: { slug: dto.slug } });
      if (existing) throw new ConflictException('Tenant slug already exists');

      const tenant = await tenantRepo.save(
        tenantRepo.create({
          name: dto.name,
          slug: dto.slug,
          is_active: true,
          config: { roles: templateRoles },
        }),
      );

      const user = await userRepo.save(
        userRepo.create({
          tenant_id: tenant.id,
          email: dto.owner_email,
          password_hash,
          roles: ['OWNER'],
          department_id: null,
          is_active: true,
        }),
      );

      this.logger.log(
        `Provisioned tenant slug=${tenant.slug} id=${tenant.id} owner=${user.id} roles=${templateRoles.join(',')}`,
      );
      await this.audit.log({
        action: AUDIT_ACTIONS.TENANT_PROVISIONED,
        tenant_id: tenant.id,
        user_id: user.id,
        metadata: {
          slug: tenant.slug,
          template: dto.template ?? null,
          roles: templateRoles,
        },
      });
      return {
        tenant: { id: tenant.id, slug: tenant.slug, name: tenant.name, roles: templateRoles },
        owner: { id: user.id, email: user.email, roles: user.roles },
      };
    });
  }
}
