export interface JwtPayload {
  sub: string;
  tenant_id: string;
  roles: string[];
  department_id: string | null;
  /** STORY-018 — UUID v4 issued at sign time, used for instant revocation. */
  jti: string;
  iat: number;
  exp: number;
}

export interface AuthenticatedUser {
  user_id: string;
  tenant_id: string;
  roles: string[];
  department_id: string | null;
  /** STORY-018 — propagated from JWT for blacklist checks and logout. */
  jti: string;
  /** STORY-018 — JWT exp claim (seconds since epoch). */
  exp: number;
}
