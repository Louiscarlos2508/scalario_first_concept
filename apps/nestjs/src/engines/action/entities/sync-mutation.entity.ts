import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';

@Entity({ name: 'sync_mutations' })
@Index('idx_sync_mutations_client_id', ['client_mutation_id'])
@Index('idx_sync_mutations_tenant_status', ['tenant_id', 'status'])
export class SyncMutation {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', unique: true })
  client_mutation_id!: string;

  @Column({ type: 'uuid' })
  tenant_id!: string;

  @Column({ type: 'uuid' })
  user_id!: string;

  @Column({ type: 'text' })
  module_id!: string;

  @Column({ type: 'text' })
  action!: string;

  @Column({ type: 'jsonb', default: () => "'{}'::jsonb" })
  payload!: Record<string, unknown>;

  @Column({ type: 'jsonb', nullable: true })
  result!: Record<string, unknown> | null;

  @Column({ type: 'text', default: 'pending' })
  status!: string;

  @Column({ type: 'jsonb', nullable: true })
  conflict_data!: Record<string, unknown> | null;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;

  @Column({ type: 'timestamptz', nullable: true })
  processed_at!: Date | null;
}
