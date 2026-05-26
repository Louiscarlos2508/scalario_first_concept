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
import { AuthService } from '../core/auth/auth.service';
import { Tenant } from '../core/auth/entities/tenant.entity';
import { User } from '../core/auth/entities/user.entity';
import { SUPER_ADMIN } from '../core/security/constants';
import { loadTemplateRoles } from '../catalog-loader/templates.loader';
import { AuditLogService } from '../core/audit/services/audit-log.service';
import { AUDIT_ACTIONS } from '../core/audit/constants';
import { ProvisionTenantDto, ProvisionTenantSchema } from './dto/provision.dto';
import { generateHandle } from './handle-generator';

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

      if (dto.handle) {
        const handleExists = await tenantRepo.findOne({ where: { handle: dto.handle } });
        if (handleExists) throw new ConflictException('Tenant handle already taken');
      }

      const handle = dto.handle ?? (await generateHandle(dto.name, tenantRepo));

      const tenant = await tenantRepo.save(
        tenantRepo.create({
          name: dto.name,
          slug: dto.slug,
          handle,
          is_active: true,
          network_public: false,
          network_profile: {},
          config: {
            roles: templateRoles,
            network: {
              public: false,
              expose_modules: [],
              allow_inbound_orders: false,
              allow_inbound_payments: false,
            },
          },
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
        `Provisioned tenant slug=${tenant.slug} handle=${tenant.handle} id=${tenant.id} owner=${user.id} roles=${templateRoles.join(',')}`,
      );
      await this.audit.log({
        action: AUDIT_ACTIONS.TENANT_PROVISIONED,
        tenant_id: tenant.id,
        user_id: user.id,
        metadata: {
          slug: tenant.slug,
          handle: tenant.handle,
          template: dto.template ?? null,
          roles: templateRoles,
        },
      });
      return {
        tenant: { id: tenant.id, slug: tenant.slug, handle: tenant.handle, name: tenant.name, roles: templateRoles },
        owner: { id: user.id, email: user.email, roles: user.roles },
      };
    });
  }
}
