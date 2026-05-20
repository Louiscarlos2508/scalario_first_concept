import {
  Entity,
  Column,
  Index,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'workflow_states' })
@Index('idx_workflow_states_entity_id', ['entity_id'])
export class WorkflowStateEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  @Index()
  tenant_id!: string;

  @Column({ type: 'uuid', nullable: true })
  entity_id!: string | null;

  @Column({ type: 'text' })
  workflow_id!: string;

  @Column({ type: 'text' })
  current_state!: string;

  @Column({ type: 'jsonb', default: () => "'[]'::jsonb" })
  history!: any;

  @Column({ type: 'uuid', nullable: true })
  triggered_by!: string | null;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at!: Date;
}
