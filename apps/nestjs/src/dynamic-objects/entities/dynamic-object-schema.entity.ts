import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';
import { TenantScopedEntity } from '../../common/entities/tenant-scoped.entity';

@Entity({ name: 'dynamic_object_schemas' })
@Index('idx_dynamic_schemas_tenant', ['tenant_id'])
@Index('idx_dynamic_schemas_name', ['tenant_id', 'name'], { unique: true })
export class DynamicObjectSchema extends TenantScopedEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 100 })
  name!: string;

  @Column({ type: 'varchar', length: 100 })
  plural_name!: string;

  @Column({ type: 'varchar', length: 50, nullable: true })
  icon!: string | null;

  @Column({ type: 'jsonb', default: () => "'{}'::jsonb" })
  schema!: Record<string, any>;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at!: Date;
}
