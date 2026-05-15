export interface ITokenBlacklist {
  /** Push a key (jti or refresh token hash) onto the blacklist. No-op if ttl <= 0. */
  add(key: string, ttlSeconds: number): Promise<void>;
  /** Returns true iff the key is currently blacklisted. Fail-open on Redis errors. */
  isRevoked(key: string): Promise<boolean>;
}
