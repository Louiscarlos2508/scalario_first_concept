import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { TenantScopedEntity } from '../../common/entities/tenant-scoped.entity';
import { DynamicObjectSchema } from './dynamic-object-schema.entity';

@Entity({ name: 'dynamic_object_records' })
@Index('idx_dynamic_records_tenant_schema', ['tenant_id', 'schema_id'])
// Index GIN for querying JSONB data efficiently (to be created via migration if needed)
@Index('idx_dynamic_records_data_gin', ['data']) 
export class DynamicObjectRecord extends TenantScopedEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  schema_id!: string;

  @ManyToOne(() => DynamicObjectSchema, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'schema_id' })
  schema_obj!: DynamicObjectSchema;

  @Column({ type: 'jsonb', default: () => "'{}'::jsonb" })
  data!: Record<string, any>;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at!: Date;
}
