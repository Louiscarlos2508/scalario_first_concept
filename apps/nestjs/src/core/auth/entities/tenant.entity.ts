import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

export interface TenantConfig {
  roles?: string[];
  /** STORY-019 — Attribute-Based Access Control rules, evaluated by CASL. */
  abac_rules?: Record<string, unknown>[];
  /** STORY-V14-013 — Phase 4 network anticipation (disabled by default). */
  network?: {
    public?: boolean;
    expose_modules?: string[];
    allow_inbound_orders?: boolean;
    allow_inbound_payments?: boolean;
  };
  [k: string]: unknown;
}

@Entity({ name: 'tenants' })
export class Tenant {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'text' })
  name!: string;

  @Column({ type: 'text', unique: true })
  slug!: string;

  /** STORY-V14-013 — Phase 4 network handle (@handle), unique partial index (NULL ignored). */
  @Column({ type: 'text', unique: false, nullable: true })
  handle?: string | null;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  is_active!: boolean;

  @Column({ name: 'network_public', type: 'boolean', default: false })
  network_public?: boolean;

  @Column({ name: 'network_profile', type: 'jsonb', default: {} })
  network_profile?: Record<string, unknown>;

  @Column({ type: 'jsonb', default: () => `'{"roles":["OWNER"]}'::jsonb` })
  config!: TenantConfig;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  created_at!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updated_at!: Date;
}
