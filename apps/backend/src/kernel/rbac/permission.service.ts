import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class PermissionService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Returns the role name for a user within a tenant, or null if not a member.
   */
  async getUserRoleName(userId: string, tenantId: string): Promise<string | null> {
    const member = await this.prisma.organizationMember.findUnique({
      where: {
        organizationId_userId: { organizationId: tenantId, userId },
      },
      include: { role: true },
    });
    return member?.role.name ?? null;
  }

  /**
   * Returns true if the user holds a permission within the tenant.
   * Loads role → role_permissions → permissions chain.
   */
  async hasPermission(
    userId: string,
    tenantId: string,
    permissionCode: string,
  ): Promise<boolean> {
    const member = await this.prisma.organizationMember.findUnique({
      where: {
        organizationId_userId: { organizationId: tenantId, userId },
      },
      include: {
        role: {
          include: {
            permissions: {
              include: { permission: true },
            },
          },
        },
      },
    });
    if (!member) return false;
    return member.role.permissions.some(
      (rp) => rp.permission.code === permissionCode,
    );
  }
}
