import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { SuperAdminGuard } from '../guards/super-admin.guard';
import { PlanDefinitionService } from './plan-definition.service';
import { CreatePlanDefinitionDto } from './dto/create-plan-definition.dto';
import { UpdatePlanDefinitionDto } from './dto/update-plan-definition.dto';

@Controller('admin/plans')
@UseGuards(SuperAdminGuard)
export class PlanDefinitionController {
  constructor(private readonly planDefinitionService: PlanDefinitionService) {}

  @Get()
  findAll() {
    return this.planDefinitionService.findAll();
  }

  @Post()
  create(@Body() dto: CreatePlanDefinitionDto) {
    return this.planDefinitionService.create(dto);
  }

  @Patch(':code')
  update(@Param('code') code: string, @Body() dto: UpdatePlanDefinitionDto) {
    return this.planDefinitionService.update(code, dto);
  }

  @Delete(':code')
  deactivate(@Param('code') code: string) {
    return this.planDefinitionService.deactivate(code);
  }
}
