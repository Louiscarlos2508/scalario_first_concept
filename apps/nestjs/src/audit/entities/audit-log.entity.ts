import { Column, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';

/**
 * STORY-020 — read-only TypeORM mirror of the `audit_logs` table.
 * The table is INSERT/SELECT-only at the DB level (privileges revoked
 * for `scalario_app`); the entity exists so the GET endpoint can select
 * paginated rows via the QueryBuilder API.
 */
@Entity({ name: 'audit_logs' })
@Index('idx_audit_logs_tenant_time', ['tenant_id', 'created_at'])
export class AuditLog {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  tenant_id!: string;

  @Column({ type: 'uuid', nullable: true })
  user_id!: string | null;

  @Column({ type: 'text' })
  action!: string;

  @Column({ type: 'text', nullable: true })
  module_id!: string | null;

  @Column({ type: 'uuid', nullable: true })
  entity_id!: string | null;

  @Column({ type: 'text', nullable: true })
  payload_hash!: string | null;

  @Column({ type: 'jsonb', default: () => `'{}'::jsonb` })
  metadata!: Record<string, unknown>;

  @Column({ type: 'timestamptz', default: () => 'NOW()' })
  created_at!: Date;
}
