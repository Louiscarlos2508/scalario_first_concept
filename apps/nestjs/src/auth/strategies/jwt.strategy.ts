import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import type { AuthenticatedUser, JwtPayload } from '../interfaces/jwt-payload.interface';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor() {
    const secret = process.env.JWT_SECRET;
    if (!secret || secret.length < 32) {
      throw new Error('JWT_SECRET must be set and at least 32 characters long (>= 256 bits).');
    }
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: secret,
      algorithms: ['HS256'],
      // ±30s clock skew tolerance — handled by jsonwebtoken default; explicit:
      jsonWebTokenOptions: { clockTolerance: 30 },
    });
  }

  validate(payload: JwtPayload): AuthenticatedUser {
    return {
      user_id: payload.sub,
      tenant_id: payload.tenant_id,
      roles: payload.roles,
      department_id: payload.department_id,
      jti: payload.jti,
      exp: payload.exp,
    };
  }
}
