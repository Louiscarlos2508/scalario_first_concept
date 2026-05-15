import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Tenant } from '../auth/entities/tenant.entity';
import { RbacGuard } from './guards/rbac.guard';
import { RolesService } from './services/roles.service';
import { RlsBypassService } from '../common/database/rls-bypass.service';

/**
 * SecurityModule — STORY-015 + STORY-017.
 *
 * Registers Layer 2 RBAC and the Layer 5 RLS bypass helper. Order
 * matters: `AppModule.imports` lists `AuthModule` BEFORE
 * `SecurityModule`, which means `JwtAuthGuard` (registered as APP_GUARD
 * in AuthModule) runs before `RbacGuard` here — authentication is
 * established before role checks.
 *
 * `RlsBypassService` is the only sanctioned way to issue cross-tenant
 * queries; see the whitelist in `common/database/rls-bypass.service.ts`.
 */
@Module({
  imports: [TypeOrmModule.forFeature([Tenant])],
  providers: [RolesService, RlsBypassService, { provide: APP_GUARD, useClass: RbacGuard }],
  exports: [RolesService, RlsBypassService],
})
export class SecurityModule {}
