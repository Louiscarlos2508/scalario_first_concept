import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'entities' })
@Index('idx_entities_tenant_module', ['tenant_id', 'module_id'])
@Index('idx_entities_tenant_type', ['tenant_id', 'entity_type'])
@Index('idx_entities_status', ['tenant_id', 'status'])
@Index('idx_entities_created_at', ['tenant_id', 'created_at'])
export class EntityRecord {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  @Index()
  tenant_id!: string;

  @Column({ type: 'text' })
  module_id!: string;

  @Column({ type: 'text' })
  entity_type!: string;

  @Column({ type: 'jsonb', default: () => "'{}'::jsonb" })
  data!: Record<string, unknown>;

  @Column({ type: 'text', default: 'active' })
  status!: string;

  @Column({ type: 'integer', default: 1 })
  version!: number;

  @Column({ type: 'jsonb', nullable: true })
  vector_clock!: Record<string, unknown> | null;

  @Column({ type: 'uuid', nullable: true })
  created_by!: string | null;

  @Column({ type: 'uuid', nullable: true })
  updated_by!: string | null;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at!: Date;
}
