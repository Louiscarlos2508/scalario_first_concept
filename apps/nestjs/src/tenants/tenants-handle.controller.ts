import {
  Body,
  ConflictException,
  Controller,
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
import { Tenant } from '../core/auth/entities/tenant.entity';
import { SUPER_ADMIN } from '../core/security/constants';
import { AuditLogService } from '../core/audit/services/audit-log.service';
import { AUDIT_ACTIONS } from '../core/audit/constants';
import { UpdateTenantHandleDto, UpdateTenantHandleSchema } from './dto/update-handle.dto';

/**
 * PATCH /tenants/:slug/handle — STORY-V14-013.
 * Layer 2 + ABAC protected: only OWNER of the tenant or SUPER_ADMIN.
 */
@Controller('tenants')
export class TenantsHandleController {
  private readonly logger = new Logger(TenantsHandleController.name);

  constructor(
    @InjectRepository(Tenant) private readonly tenantRepo: Repository<Tenant>,
    private readonly audit: AuditLogService,
  ) {}

  @Patch(':slug/handle')
  @Roles('OWNER', SUPER_ADMIN)
  @UsePipes(new ZodValidationPipe(UpdateTenantHandleSchema))
  async updateHandle(
    @Param('slug') slug: string,
    @Body() dto: UpdateTenantHandleDto,
  ) {
    const tenant = await this.tenantRepo.findOne({ where: { slug } });
    if (!tenant) throw new NotFoundException(`Tenant ${slug} not found`);

    if (tenant.handle === dto.handle) {
      return { handle: tenant.handle };
    }

    const existing = await this.tenantRepo.findOne({
      where: { handle: dto.handle },
      select: ['id'],
    });
    if (existing) {
      throw new ConflictException({ message: 'Handle already taken by another tenant', handle: dto.handle });
    }

    const previousHandle = tenant.handle;
    tenant.handle = dto.handle;
    await this.tenantRepo.save(tenant);

    await this.audit.log({
      action: AUDIT_ACTIONS.TENANT_HANDLE_UPDATED,
      tenant_id: tenant.id,
      metadata: { previous: previousHandle, current: dto.handle },
    });

    this.logger.log(`Handle updated for tenant ${slug}: ${previousHandle} → ${dto.handle}`);
    return { handle: tenant.handle };
  }
}
