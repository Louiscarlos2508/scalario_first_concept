import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';

@Entity({ name: 'refresh_tokens' })
@Index('idx_refresh_tokens_hash', ['token_hash'])
@Index('idx_refresh_tokens_user', ['user_id'])
export class RefreshToken {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  user_id!: string;

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenant_id!: string;

  @Column({ name: 'token_hash', type: 'text', unique: true })
  token_hash!: string;

  @Column({ name: 'expires_at', type: 'timestamptz' })
  expires_at!: Date;

  @Column({ name: 'revoked_at', type: 'timestamptz', nullable: true })
  revoked_at!: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  created_at!: Date;
}
