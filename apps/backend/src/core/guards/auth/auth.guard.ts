import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { SupabaseService } from '../../services/supabase/supabase.service';

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private readonlysupabaseService: SupabaseService) { }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    if (!authHeader) {
      throw new UnauthorizedException('Missing Authorization Header');
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      throw new UnauthorizedException('Missing Bearer Token');
    }

    const { data: { user }, error } = await this.readonlysupabaseService.getClient().auth.getUser(token);

    if (error || !user) {
      throw new UnauthorizedException('Invalid Token');
    }

    // Attach user to request for downstream controllers
    request.user = user;
    return true;
  }
}
