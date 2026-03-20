import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

const WHITELIST = ['/auth/login', '/auth/refresh', '/settings/billing'];
const TTL_MS = 60_000;

@Injectable()
export class BillingGuard implements CanActivate {
  private cache = new Map<string, { status: string; cachedAt: number }>();

  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const tenantId: string | undefined = request.tenantId;

    // No tenant = public/admin route, pass through
    if (!tenantId) return true;

    // Whitelist check
    const url: string = request.url ?? '';
    if (WHITELIST.some((path) => url.includes(path))) return true;

    const status = await this._getStatus(tenantId);
    if (status === 'suspended') {
      throw new ForbiddenException({
        error: 'TENANT_SUSPENDED',
        message: 'Abonnement expiré — contactez votre administrateur',
      });
    }

    return true;
  }

  invalidate(tenantId: string): void {
    this.cache.delete(tenantId);
  }

  private async _getStatus(tenantId: string): Promise<string> {
    const cached = this.cache.get(tenantId);
    if (cached && Date.now() - cached.cachedAt < TTL_MS) {
      return cached.status;
    }
    const tenant = await this.prisma.tenant.findUnique({
      where: { id: tenantId },
      select: { billingStatus: true },
    });
    const status = tenant?.billingStatus ?? 'active';
    this.cache.set(tenantId, { status, cachedAt: Date.now() });
    return status;
  }
}
