import { Controller, Get, Post, Body, Param, UseGuards, Req } from '@nestjs/common';
import { DynamicObjectsService } from './dynamic-objects.service';
import { BduiGeneratorService } from './bdui-generator.service';
import { JwtAuthGuard } from '../core/auth/guards/jwt-auth.guard';
import { Request } from 'express';

@Controller('dynamic-objects')
@UseGuards(JwtAuthGuard)
export class DynamicObjectsController {
  constructor(
    private readonly dynamicObjectsService: DynamicObjectsService,
    private readonly bduiGeneratorService: BduiGeneratorService,
  ) {}

  @Post('schemas')
  async createSchema(@Req() req: Request, @Body() body: any) {
    const tenantId = (req.user as any).tenant_id;
    return this.dynamicObjectsService.createSchema(tenantId, body);
  }

  @Get('schemas')
  async getSchemas(@Req() req: Request) {
    const tenantId = (req.user as any).tenant_id;
    return this.dynamicObjectsService.getSchemas(tenantId);
  }

  @Post('schemas/:schemaId/records')
  async createRecord(
    @Req() req: Request,
    @Param('schemaId') schemaId: string,
    @Body() body: any,
  ) {
    const tenantId = (req.user as any).tenant_id;
    return this.dynamicObjectsService.createRecord(tenantId, schemaId, body.data);
  }

  @Get('schemas/:schemaId/records')
  async getRecords(@Req() req: Request, @Param('schemaId') schemaId: string) {
    const tenantId = (req.user as any).tenant_id;
    return this.dynamicObjectsService.getRecords(tenantId, schemaId);
  }

  // --- Points d'accès pour l'auto-génération BDUI ---

  @Get('schemas/:schemaId/bdui/list')
  async getBduiList(@Req() req: Request, @Param('schemaId') schemaId: string) {
    const tenantId = (req.user as any).tenant_id;
    const schema = await this.dynamicObjectsService.getSchema(tenantId, schemaId);
    return this.bduiGeneratorService.generateListScreen(schema);
  }

  @Get('schemas/:schemaId/bdui/form')
  async getBduiForm(@Req() req: Request, @Param('schemaId') schemaId: string) {
    const tenantId = (req.user as any).tenant_id;
    const schema = await this.dynamicObjectsService.getSchema(tenantId, schemaId);
    return this.bduiGeneratorService.generateFormScreen(schema);
  }
}
