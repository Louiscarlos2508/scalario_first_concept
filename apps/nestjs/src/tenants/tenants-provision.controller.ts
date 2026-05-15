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
import { Public } from '../common/decorators/public.decorator';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { AuthService } from '../auth/auth.service';
import { Tenant } from '../auth/entities/tenant.entity';
import { User } from '../auth/entities/user.entity';
import { ProvisionTenantDto, ProvisionTenantSchema } from './dto/provision.dto';

/**
 * POST /tenants/provision — bootstrap a tenant with its first OWNER.
 *
 * Architecturally protected by `@Roles('SUPER_ADMIN')` (STORY-015). Phase 1
 * it is marked `@Public()` because RolesGuard does not exist yet — STORY-015
 * will replace the decorator. FR-009 AC: full transaction must complete in
 * under 30 seconds (bcrypt cost 12 dominates wall time).
 */
@Controller('tenants')
export class TenantsProvisionController {
  private readonly logger = new Logger(TenantsProvisionController.name);

  constructor(@InjectDataSource() private readonly ds: DataSource) {}

  @Public()
  @Post('provision')
  @HttpCode(HttpStatus.CREATED)
  @UsePipes(new ZodValidationPipe(ProvisionTenantSchema))
  async provision(@Body() dto: ProvisionTenantDto) {
    const password_hash = await AuthService.hashPassword(dto.owner_password);

    return this.ds.transaction(async (m) => {
      const tenantRepo = m.getRepository(Tenant);
      const userRepo = m.getRepository(User);

      const existing = await tenantRepo.findOne({ where: { slug: dto.slug } });
      if (existing) throw new ConflictException('Tenant slug already exists');

      const tenant = await tenantRepo.save(
        tenantRepo.create({ name: dto.name, slug: dto.slug, is_active: true }),
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

      this.logger.log(`Provisioned tenant slug=${tenant.slug} id=${tenant.id} owner=${user.id}`);
      return {
        tenant: { id: tenant.id, slug: tenant.slug, name: tenant.name },
        owner: { id: user.id, email: user.email, roles: user.roles },
      };
    });
  }
}
