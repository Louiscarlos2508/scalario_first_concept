import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class SuperAdminGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const userId: string | undefined = request.user?.id;

    if (!userId) {
      throw new UnauthorizedException('Missing user context');
    }

    const member = await this.prisma.organizationMember.findFirst({
      where: {
        userId,
        role: { name: 'superadmin' },
      },
      include: { role: true },
    });

    if (!member) {
      throw new ForbiddenException('Superadmin role required');
    }

    return true;
  }
}
