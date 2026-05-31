import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';
import type { ExecutionContext } from '../../shared/engine-core';

@Entity({ name: 'flow_pending_delays' })
@Index('idx_pending_delays_resume_at', ['resume_at'])
export class FlowPendingDelay {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'text' })
  flow_id!: string;

  @Column({ type: 'text' })
  step_id!: string;

  @Column({ type: 'uuid' })
  @Index()
  tenant_id!: string;

  @Column({ type: 'text', default: '' })
  user_id!: string;

  @Column({ type: 'jsonb', default: () => "'{}'::jsonb" })
  context!: ExecutionContext;

  @Column({ type: 'jsonb', default: () => "'{}'::jsonb" })
  flow_definition!: Record<string, unknown>;

  @Column({ type: 'timestamptz' })
  resume_at!: Date;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;
}
