import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Tenant } from '../../auth/entities/tenant.entity';
import { AbilityFactory } from './ability.factory';
import { CaslAbacEngine } from './engines/casl.engine';
import { ABAC_ENGINE } from './engines/abac-engine.interface';
import { AbacGuard } from './guards/abac.guard';
import { AbilityMiddleware } from './middleware/ability.middleware';

/**
 * STORY-019 — Layer 3 ABAC.
 *
 * Order matters in AppModule.imports : SecurityModule (RBAC Layer 2)
 * registers its guard before this module, and AbacGuard's APP_GUARD
 * registration ensures it runs AFTER both JwtAuthGuard (AuthModule)
 * and RbacGuard (SecurityModule) — NestJS chains APP_GUARD by
 * registration order.
 *
 * `AbilityMiddleware` is wired in `AppModule.configure()` so it runs
 * before the guards and populates `req.ability`.
 */
@Module({
  imports: [
    TypeOrmModule.forFeature([Tenant]),
    JwtModule.registerAsync({
      useFactory: () => {
        const secret = process.env.JWT_SECRET;
        if (!secret || secret.length < 32) {
          throw new Error('JWT_SECRET must be set and at least 32 characters long (>= 256 bits).');
        }
        return {
          secret,
          signOptions: { algorithm: 'HS256' },
          verifyOptions: { algorithms: ['HS256'], clockTolerance: 30 },
        };
      },
    }),
  ],
  providers: [
    CaslAbacEngine,
    { provide: ABAC_ENGINE, useExisting: CaslAbacEngine },
    AbilityFactory,
    AbilityMiddleware,
    { provide: APP_GUARD, useClass: AbacGuard },
  ],
  exports: [AbilityFactory, AbilityMiddleware, CaslAbacEngine, ABAC_ENGINE],
})
export class AbacModule {}
