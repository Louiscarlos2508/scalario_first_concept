import { ExecutionContext, createParamDecorator } from '@nestjs/common';
import type { AuthenticatedUser } from '../../auth/interfaces/jwt-payload.interface';

export const CurrentUser = createParamDecorator(
  (data: keyof AuthenticatedUser | undefined, ctx: ExecutionContext) => {
    const req = ctx.switchToHttp().getRequest<{ user?: AuthenticatedUser }>();
    const user = req.user;
    if (!user) return undefined;
    return data ? user[data] : user;
  },
);
