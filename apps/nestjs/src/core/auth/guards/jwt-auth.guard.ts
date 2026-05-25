import { ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import { TokenBlacklistService } from '../../cache/services/token-blacklist.service';
import { IS_PUBLIC_KEY } from '../../../common/decorators/public.decorator';
import type { AuthenticatedUser } from '../interfaces/jwt-payload.interface';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(
    private readonly reflector: Reflector,
    private readonly blacklist: TokenBlacklistService,
  ) {
    super();
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    const ok = (await super.canActivate(context)) as boolean;
    if (!ok) return false;

    const req = context.switchToHttp().getRequest<{ user?: AuthenticatedUser }>();
    const jti = req.user?.jti;
    if (jti && (await this.blacklist.isRevoked(jti))) {
      throw new UnauthorizedException('Token revoked');
    }
    return true;
  }
}
