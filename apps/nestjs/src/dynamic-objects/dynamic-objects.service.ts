import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DynamicObjectSchema } from './entities/dynamic-object-schema.entity';
import { DynamicObjectRecord } from './entities/dynamic-object-record.entity';

@Injectable()
export class DynamicObjectsService {
  constructor(
    @InjectRepository(DynamicObjectSchema)
    private schemaRepo: Repository<DynamicObjectSchema>,
    @InjectRepository(DynamicObjectRecord)
    private recordRepo: Repository<DynamicObjectRecord>,
  ) {}

  async createSchema(tenantId: string, schemaDto: Partial<DynamicObjectSchema>): Promise<DynamicObjectSchema> {
    const schema = this.schemaRepo.create({
      ...schemaDto,
      tenant_id: tenantId,
    });
    return this.schemaRepo.save(schema);
  }

  async getSchemas(tenantId: string): Promise<DynamicObjectSchema[]> {
    return this.schemaRepo.find({ where: { tenant_id: tenantId } });
  }

  async getSchema(tenantId: string, schemaId: string): Promise<DynamicObjectSchema> {
    const schema = await this.schemaRepo.findOne({ where: { id: schemaId, tenant_id: tenantId } });
    if (!schema) {
      throw new NotFoundException(`Schema ${schemaId} not found`);
    }
    return schema;
  }

  async createRecord(tenantId: string, schemaId: string, data: Record<string, any>): Promise<DynamicObjectRecord> {
    // Dans un vrai ERP, nous ferions une validation JSON Schema ici contre le DynamicObjectSchema
    const record = this.recordRepo.create({
      tenant_id: tenantId,
      schema_id: schemaId,
      data,
    });
    return this.recordRepo.save(record);
  }

  async getRecords(tenantId: string, schemaId: string): Promise<DynamicObjectRecord[]> {
    return this.recordRepo.find({ where: { schema_id: schemaId, tenant_id: tenantId } });
  }
}
