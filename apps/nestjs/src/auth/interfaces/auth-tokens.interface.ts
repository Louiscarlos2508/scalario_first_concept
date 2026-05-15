export interface AuthTokens {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  user: {
    id: string;
    email: string;
    roles: string[];
    department_id: string | null;
  };
}
