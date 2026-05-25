import {
  Controller,
  ForbiddenException,
  Get,
  NotFoundException,
  Param,
  Query,
  UsePipes,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Roles } from '../../../common/decorators/roles.decorator';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { ZodValidationPipe } from '../../../common/pipes/zod-validation.pipe';
import { AbacAction } from '../../security/abac/decorators/abac-action.decorator';
import { SUPER_ADMIN } from '../../security/constants';
import { Tenant } from '../../auth/entities/tenant.entity';
import { AuditLog } from '../entities/audit-log.entity';
import type { AuthenticatedUser } from '../../auth/interfaces/jwt-payload.interface';
import {
  AuditQueryDto,
  AuditQuerySchema,
  decodeCursor,
  encodeCursor,
} from '../dto/audit-query.dto';

/**
 * STORY-020 — `GET /tenants/:slug/audit-logs`.
 *
 * OWNER (of that tenant) or SUPER_ADMIN only — enforced by RbacGuard +
 * the slug-vs-jwt tenant check. ABAC layer additionally requires
 * `read AuditLog`; tenants who don't grant it must explicitly add a
 * `can read AuditLog` rule (permissive default means it works out of
 * the box, see STORY-019 docs).
 *
 * Cursor pagination over `(created_at DESC, id DESC)` — backed by the
 * `idx_audit_logs_tenant_time` index. With 1M rows + 30-day range, a
 * full page (100 rows) lands in <200ms (AC-20).
 */
@Controller('tenants')
export class AuditController {
  constructor(
    @InjectRepository(Tenant) private readonly tenantRepo: Repository<Tenant>,
    @InjectRepository(AuditLog) private readonly auditRepo: Repository<AuditLog>,
  ) {}

  @Get(':slug/audit-logs')
  @Roles('OWNER', SUPER_ADMIN)
  @AbacAction('read', 'AuditLog')
  @UsePipes(new ZodValidationPipe(AuditQuerySchema))
  async list(
    @Param('slug') slug: string,
    @Query() query: AuditQueryDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<{
    entries: AuditLog[];
    next_cursor: string | null;
  }> {
    const tenant = await this.tenantRepo.findOne({
      where: { slug },
      select: ['id'],
    });
    if (!tenant) throw new NotFoundException(`Tenant ${slug} not found`);

    // SUPER_ADMIN may query any tenant; OWNER may only query their own.
    if (!user.roles.includes(SUPER_ADMIN) && user.tenant_id !== tenant.id) {
      throw new ForbiddenException('Cross-tenant audit query');
    }

    const qb = this.auditRepo
      .createQueryBuilder('a')
      .where('a.tenant_id = :tenant_id', { tenant_id: tenant.id })
      .orderBy('a.created_at', 'DESC')
      .addOrderBy('a.id', 'DESC')
      .limit(query.limit + 1); // +1 to detect a next page without a count.

    if (query.from) qb.andWhere('a.created_at >= :from', { from: new Date(query.from) });
    if (query.to) qb.andWhere('a.created_at <= :to', { to: new Date(query.to) });
    if (query.user_id) qb.andWhere('a.user_id = :user_id', { user_id: query.user_id });
    if (query.action) qb.andWhere('a.action = :action', { action: query.action });
    if (query.module_id) qb.andWhere('a.module_id = :module_id', { module_id: query.module_id });

    if (query.cursor) {
      const cur = decodeCursor(query.cursor);
      if (!cur) throw new ForbiddenException('Invalid cursor');
      qb.andWhere('(a.created_at, a.id) < (:cur_at, :cur_id)', {
        cur_at: new Date(cur.created_at),
        cur_id: cur.id,
      });
    }

    const rows = await qb.getMany();
    let next_cursor: string | null = null;
    if (rows.length > query.limit) {
      const last = rows[query.limit - 1];
      rows.length = query.limit;
      next_cursor = encodeCursor({
        created_at: last.created_at.toISOString(),
        id: last.id,
      });
    }
    return { entries: rows, next_cursor };
  }
}
