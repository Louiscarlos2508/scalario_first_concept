import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { Tenant } from './entities/tenant.entity';
import { User } from './entities/user.entity';
import { RefreshToken } from './entities/refresh-token.entity';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { JwtStrategy } from './strategies/jwt.strategy';
import { LocalStrategy } from './strategies/local.strategy';

@Module({
  imports: [
    TypeOrmModule.forFeature([Tenant, User, RefreshToken]),
    PassportModule.register({ defaultStrategy: 'jwt' }),
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
  controllers: [AuthController],
  providers: [
    AuthService,
    JwtStrategy,
    LocalStrategy,
    { provide: APP_GUARD, useClass: JwtAuthGuard },
  ],
  exports: [AuthService, JwtModule, TypeOrmModule],
})
export class AuthModule {}
