import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreatePlanDefinitionDto } from './dto/create-plan-definition.dto';
import { UpdatePlanDefinitionDto } from './dto/update-plan-definition.dto';

@Injectable()
export class PlanDefinitionService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll() {
    return this.prisma.planDefinition.findMany({
      orderBy: { monthlyPrice: 'asc' },
    });
  }

  async findByCode(code: string) {
    const plan = await this.prisma.planDefinition.findUnique({ where: { code } });
    if (!plan) throw new NotFoundException(`Plan "${code}" introuvable ou inactif`);
    return plan;
  }

  async create(dto: CreatePlanDefinitionDto) {
    const existing = await this.prisma.planDefinition.findUnique({ where: { code: dto.code } });
    if (existing) {
      throw new ConflictException('Un plan avec ce code existe déjà');
    }
    return this.prisma.planDefinition.create({
      data: {
        code: dto.code,
        name: dto.name,
        monthlyPrice: dto.monthlyPrice,
        maxUsers: dto.maxUsers,
        includedModules: dto.includedModules,
        suggestedInstallationFee: dto.suggestedInstallationFee ?? null,
        suggestedTrainingFee: dto.suggestedTrainingFee ?? null,
      },
    });
  }

  async update(code: string, dto: UpdatePlanDefinitionDto) {
    await this.findByCode(code);
    const data: Record<string, unknown> = {};
    if (dto.name !== undefined) data.name = dto.name;
    if (dto.monthlyPrice !== undefined) data.monthlyPrice = dto.monthlyPrice;
    if (dto.maxUsers !== undefined) data.maxUsers = dto.maxUsers;
    if (dto.includedModules !== undefined) data.includedModules = dto.includedModules;
    if (dto.suggestedInstallationFee !== undefined) data.suggestedInstallationFee = dto.suggestedInstallationFee;
    if (dto.suggestedTrainingFee !== undefined) data.suggestedTrainingFee = dto.suggestedTrainingFee;
    if (dto.isActive !== undefined) data.isActive = dto.isActive;
    return this.prisma.planDefinition.update({ where: { code }, data });
  }

  async deactivate(code: string) {
    await this.findByCode(code);
    return this.prisma.planDefinition.update({
      where: { code },
      data: { isActive: false },
    });
  }
}
