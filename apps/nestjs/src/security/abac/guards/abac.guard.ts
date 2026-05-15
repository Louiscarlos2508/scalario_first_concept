import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  Logger,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ABAC_ACTION_KEY, type AbacActionMetadata } from '../decorators/abac-action.decorator';
import type { AbacAbility } from '../types';

interface AbacRequest {
  user?: { user_id?: string; tenant_id?: string };
  ability?: AbacAbility;
}

/**
 * STORY-019 — Layer 3 ABAC guard.
 *
 * Reads `@AbacAction(action, subject)` from the handler / class and
 * evaluates `req.ability.can(action, subject)`. Routes without the
 * decorator pass through unchanged — public routes and strict-RBAC
 * routes stay unaffected.
 *
 * Order is enforced by `AppModule` : JwtAuthGuard → RbacGuard →
 * AbacGuard. By the time we run, `req.user` is authenticated and
 * `req.ability` is populated by `AbilityMiddleware`.
 *
 * AC-09 — every deny is logged at warn-level for STORY-020 to
 * promote into the audit_logs table.
 */
@Injectable()
export class AbacGuard implements CanActivate {
  private readonly logger = new Logger(AbacGuard.name);

  constructor(private readonly reflector: Reflector) {}

  canActivate(ctx: ExecutionContext): boolean {
    const required = this.reflector.getAllAndOverride<AbacActionMetadata | undefined>(
      ABAC_ACTION_KEY,
      [ctx.getHandler(), ctx.getClass()],
    );
    if (!required) return true;

    const req = ctx.switchToHttp().getRequest<AbacRequest>();
    const ability = req.ability;
    if (!ability) {
      this.logger.warn(
        `ABAC_DENY action=${required.action} subject=${required.subject} reason=missing_ability user=${req.user?.user_id ?? 'anon'}`,
      );
      throw new ForbiddenException('ABAC denied');
    }

    if (!ability.can(required.action, required.subject)) {
      this.logger.warn(
        `ABAC_DENY action=${required.action} subject=${required.subject} user=${req.user?.user_id ?? 'anon'} tenant=${req.user?.tenant_id ?? 'none'}`,
      );
      throw new ForbiddenException('ABAC denied');
    }
    return true;
  }
}
