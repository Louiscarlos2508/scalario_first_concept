import { Tenant } from '../entities/tenant.entity';
import { User } from '../entities/user.entity';

/**
 * Abstraction for pluggable authentication providers.
 * Phase 1: only LocalAuthProvider (email + password + tenant_slug).
 * Phase 2: GoogleAuthProvider, AppleAuthProvider, AzureAdAuthProvider —
 * each implementation maps external identity → ({ user, tenant }) without
 * modifying AuthService.issueTokens or JWT payload shape.
 */
export interface AuthProvider {
  readonly name: 'local' | 'google' | 'apple' | 'azure-ad';
  authenticate(credentials: unknown): Promise<{ user: User; tenant: Tenant }>;
}
