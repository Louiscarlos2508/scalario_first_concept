import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'screen_configs' })
@Index('idx_screen_configs_tenant_screen', ['tenant_id', 'screen_id'])
export class ScreenConfigEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  @Index()
  tenant_id!: string;

  @Column({ type: 'text' })
  screen_id!: string;

  @Column({ type: 'text', default: '*' })
  role!: string;

  @Column({ type: 'jsonb' })
  config!: Record<string, unknown>;

  @Column({ name: 'schema_version', type: 'text', default: "'1.0.0'" })
  schema_version!: string;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  is_active!: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  created_at!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updated_at!: Date;
}
