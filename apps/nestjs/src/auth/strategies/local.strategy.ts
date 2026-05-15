import { Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy } from 'passport-local';
import { AuthService } from '../auth.service';
import type { User } from '../entities/user.entity';
import type { Tenant } from '../entities/tenant.entity';

/**
 * passport-local with three credentials via passReqToCallback. The login
 * controller usually consumes this strategy through AuthGuard('local') — but
 * we expose AuthService.login() directly for clearer error semantics. The
 * strategy is registered for symmetry and future OAuth2 parity.
 */
@Injectable()
export class LocalStrategy extends PassportStrategy(Strategy, 'local') {
  constructor(@Inject(AuthService) private readonly auth: AuthService) {
    super({
      usernameField: 'email',
      passwordField: 'password',
      passReqToCallback: true,
    });
  }

  async validate(
    req: { body?: { tenant_slug?: string } },
    email: string,
    password: string,
  ): Promise<{ user: User; tenant: Tenant }> {
    const tenant_slug = req.body?.tenant_slug;
    if (!tenant_slug) throw new UnauthorizedException('Invalid credentials');
    return this.auth.validateLocalCredentials({ email, password, tenant_slug });
  }
}
