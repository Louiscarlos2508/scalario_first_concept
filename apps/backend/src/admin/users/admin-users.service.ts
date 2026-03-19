import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { SupabaseAdminService } from '../services/supabase-admin.service';

const VALID_USER_ROLES = ['owner', 'manager', 'cashier'] as const;
type UserRole = (typeof VALID_USER_ROLES)[number];

export class CreateTenantUserDto {
  email: string;
  password: string;
  role: string;
}

export class UpdateTenantUserRoleDto {
  role: string;
}

@Injectable()
export class AdminUsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly supabaseAdmin: SupabaseAdminService,
  ) {}

  async createUser(tenantId: string, dto: CreateTenantUserDto) {
    if (!VALID_USER_ROLES.includes(dto.role as UserRole)) {
      throw new BadRequestException(`role must be one of: ${VALID_USER_ROLES.join(', ')}`);
    }

    // Step 1 — Create Supabase Auth user
    let userId: string;
    try {
      userId = await this.supabaseAdmin.createUser(dto.email, dto.password);
    } catch (err: any) {
      const message: string = err?.message ?? '';
      if (
        message.toLowerCase().includes('already') ||
        message.toLowerCase().includes('exist')
      ) {
        throw new UnprocessableEntityException({ error: 'EMAIL_ALREADY_EXISTS' });
      }
      throw new UnprocessableEntityException(message || 'Failed to create user');
    }

    // Step 2 — Get role from DB
    const role = await this.prisma.role.findUnique({
      where: { name_vertical: { name: dto.role, vertical: 'retail' } },
    });
    if (!role) {
      await this.supabaseAdmin.deleteUser(userId).catch(() => {});
      throw new InternalServerErrorException(`Role "${dto.role}" not seeded`);
    }

    // Step 3 — Create OrganizationMember (with compensation on P2002)
    let member: { organizationId: string; userId: string; role: { name: string }; createdAt: Date };
    try {
      member = await this.prisma.organizationMember.create({
        data: { organizationId: tenantId, userId, roleId: role.id },
        include: { role: true },
      });
    } catch (err: any) {
      await this.supabaseAdmin.deleteUser(userId).catch(() => {});
      if (err?.code === 'P2002') {
        throw new UnprocessableEntityException({ error: 'EMAIL_ALREADY_EXISTS' });
      }
      throw new InternalServerErrorException('Failed to create organization member');
    }

    return {
      userId,
      email: dto.email,
      role: dto.role,
      createdAt: member.createdAt,
    };
  }

  async listUsers(tenantId: string) {
    const members = await this.prisma.organizationMember.findMany({
      where: { organizationId: tenantId },
      include: { role: true },
      orderBy: { createdAt: 'asc' },
    });

    const enriched = await Promise.all(
      members.map(async (m) => {
        const supabaseUser = await this.supabaseAdmin.getUserById(m.userId);
        return {
          userId: m.userId,
          email: supabaseUser?.email ?? '',
          role: m.role.name,
          createdAt: m.createdAt,
          lastSignInAt: supabaseUser?.lastSignInAt ?? null,
        };
      }),
    );

    return enriched;
  }

  async updateUserRole(tenantId: string, userId: string, role: string) {
    if (!VALID_USER_ROLES.includes(role as UserRole)) {
      throw new BadRequestException(`role must be one of: ${VALID_USER_ROLES.join(', ')}`);
    }

    const member = await this.prisma.organizationMember.findUnique({
      where: { organizationId_userId: { organizationId: tenantId, userId } },
    });
    if (!member) throw new NotFoundException('User not found in this tenant');

    const newRole = await this.prisma.role.findUnique({
      where: { name_vertical: { name: role, vertical: 'retail' } },
    });
    if (!newRole) throw new InternalServerErrorException(`Role "${role}" not seeded`);

    const updated = await this.prisma.organizationMember.update({
      where: { organizationId_userId: { organizationId: tenantId, userId } },
      data: { roleId: newRole.id },
      include: { role: true },
    });

    const supabaseUser = await this.supabaseAdmin.getUserById(userId);

    return {
      userId,
      email: supabaseUser?.email ?? '',
      role: updated.role.name,
      createdAt: updated.createdAt,
    };
  }

  async removeUser(tenantId: string, userId: string) {
    const member = await this.prisma.organizationMember.findUnique({
      where: { organizationId_userId: { organizationId: tenantId, userId } },
      include: { role: true },
    });
    if (!member) throw new NotFoundException('User not found in this tenant');

    // Guard: cannot remove last owner
    if (member.role.name === 'owner') {
      const ownerCount = await this.prisma.organizationMember.count({
        where: { organizationId: tenantId, role: { name: 'owner' } },
      });
      if (ownerCount === 1) {
        throw new UnprocessableEntityException({ error: 'CANNOT_REMOVE_LAST_OWNER' });
      }
    }

    await this.prisma.organizationMember.delete({
      where: { organizationId_userId: { organizationId: tenantId, userId } },
    });

    await this.supabaseAdmin.banUser(userId);
  }
}
