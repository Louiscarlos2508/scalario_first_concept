import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { SupabaseService } from './supabase.service';
import { IS_PUBLIC_KEY } from './auth.decorator';

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (isPublic) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    if (!authHeader) {
      throw new UnauthorizedException('Missing Authorization Header');
    }

    const parts = authHeader.split(' ');
    if (parts.length !== 2 || !parts[1]) {
      throw new UnauthorizedException('Missing Bearer Token');
    }
    const token = parts[1];

    const {
      data: { user },
      error,
    } = await this.supabaseService.getClient().auth.getUser(token);

    if (error || !user) {
      throw new UnauthorizedException('Invalid Token');
    }

    // Session timeout: validate token age against configured timeout
    const payload = this._decodeJwtPayload(token);
    if (payload?.iat) {
      const sessionTimeoutMinutes: number =
        request.tenantSessionTimeoutMinutes ?? 480; // default 8 hours
      const tokenAgeSeconds = Math.floor(Date.now() / 1000) - payload.iat;
      const timeoutSeconds = sessionTimeoutMinutes * 60;
      if (tokenAgeSeconds > timeoutSeconds) {
        throw new UnauthorizedException(
          'Session expired. Please re-authenticate.',
        );
      }
    }

    request.user = user;
    return true;
  }

  private _decodeJwtPayload(token: string): Record<string, any> | null {
    try {
      const base64Payload = token.split('.')[1];
      if (!base64Payload) return null;
      const decoded = Buffer.from(base64Payload, 'base64').toString('utf-8');
      return JSON.parse(decoded);
    } catch {
      return null;
    }
  }
}
