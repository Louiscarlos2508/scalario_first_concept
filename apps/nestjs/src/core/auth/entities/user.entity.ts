import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  Unique,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'users' })
@Unique('users_tenant_email_unique', ['tenant_id', 'email'])
@Index('idx_users_tenant', ['tenant_id'])
@Index('idx_users_email', ['email'])
export class User {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenant_id!: string;

  @Column({ type: 'text' })
  email!: string;

  @Column({ name: 'password_hash', type: 'text' })
  password_hash!: string;

  @Column({ type: 'jsonb', default: () => `'[]'::jsonb` })
  roles!: string[];

  @Column({ name: 'department_id', type: 'uuid', nullable: true })
  department_id!: string | null;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  is_active!: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  created_at!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updated_at!: Date;
}
