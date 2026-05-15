export interface JwtPayload {
  sub: string;
  tenant_id: string;
  roles: string[];
  department_id: string | null;
  iat: number;
  exp: number;
}

export interface AuthenticatedUser {
  user_id: string;
  tenant_id: string;
  roles: string[];
  department_id: string | null;
}
