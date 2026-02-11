import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class TenantsService {
    constructor(private prisma: PrismaService) { }

    async validateTenantAccess(tenantId: string, userId: string): Promise<boolean> {
        // Validate format first to avoid DB errors
        const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
        if (!uuidRegex.test(tenantId) || !uuidRegex.test(userId)) {
            return false;
        }

        // Check if user is a member of the organization
        const member = await this.prisma.organizationMember.findUnique({
            where: {
                organizationId_userId: {
                    organizationId: tenantId,
                    userId: userId,
                },
            },
        });

        return !!member;
    }

    async getTenantConfig(tenantId: string) {
        const tenant = await this.prisma.tenant.findUnique({
            where: { id: tenantId },
        });

        if (!tenant) return null;

        return {
            id: tenant.id,
            name: tenant.name,
            settings: {
                currency: 'XOF', // Default for now, could be added to DB
                timezone: 'Africa/Abidjan' // Default
            }
        };
    }
}
