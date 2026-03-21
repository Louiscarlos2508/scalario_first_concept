import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class BusinessTypeService {
  private readonly logger = new Logger(BusinessTypeService.name);

  constructor(private readonly prisma: PrismaService) {}

  async listActive() {
    return this.prisma.businessTypeDefinition.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' },
    });
  }

  async getDefinition(code: string) {
    const businessType = await this.prisma.businessTypeDefinition.findUnique({
      where: { code },
    });

    if (!businessType || !businessType.isActive) {
      throw new NotFoundException(`Type de business introuvable : ${code}`);
    }

    return businessType;
  }

  async assignToTenant(tenantId: string, code: string) {
    // Validate business type exists and is active
    const businessType = await this.prisma.businessTypeDefinition.findUnique({
      where: { code },
    });

    if (!businessType || !businessType.isActive) {
      throw new NotFoundException(`Type de business inconnu : ${code}`);
    }

    return this.prisma.tenant.update({
      where: { id: tenantId },
      data: { businessType: code },
    });
  }

  /**
   * Returns the BusinessTypeDefinition for a tenant's assigned businessType.
   * Falls back to 'generaliste' if the type is unknown or inactive.
   */
  async getMyConfig(tenantId: string) {
    const tenant = await this.prisma.tenant.findUnique({
      where: { id: tenantId },
      select: { businessType: true },
    });
    const code = tenant?.businessType ?? 'generaliste';
    const definition = await this.prisma.businessTypeDefinition.findUnique({
      where: { code },
    });
    if (!definition || !definition.isActive) {
      const fallback = await this.prisma.businessTypeDefinition.findUnique({
        where: { code: 'generaliste' },
      });
      return fallback!;
    }
    return definition;
  }

  /**
   * Seed suggested categories for a tenant based on their business type.
   * Non-blocking: called fire-and-forget from tenant creation (Story 29-4).
   * Idempotent: skips categories that already exist for this tenant.
   */
  async seedCategories(tenantId: string, code: string): Promise<void> {
    let definition: Awaited<ReturnType<typeof this.prisma.businessTypeDefinition.findUnique>>;
    try {
      definition = await this.prisma.businessTypeDefinition.findUnique({ where: { code } });
    } catch {
      this.logger.warn(`seedCategories: could not load definition for code=${code}, skipping`);
      return;
    }

    if (!definition || !definition.isActive || definition.suggestedCategories.length === 0) {
      return;
    }

    let created = 0;
    for (const categoryName of definition.suggestedCategories) {
      const existing = await this.prisma.category.findFirst({
        where: { name: categoryName, tenantId },
      });
      if (!existing) {
        await this.prisma.category.create({
          data: { name: categoryName, tenantId },
        });
        created++;
      }
    }

    this.logger.log({
      event: 'business_type_categories_seeded',
      tenantId,
      businessType: code,
      count: created,
    });
  }
}
