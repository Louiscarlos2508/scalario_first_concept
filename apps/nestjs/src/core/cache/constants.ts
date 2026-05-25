/**
 * STORY-018 — Redis key prefixes, TTLs, channels.
 *
 * All Redis keys are namespaced to avoid collisions across the three
 * logical roles (blacklist, BDUI cache, future rate-limit). Channels are
 * separate per concern so subscribers don't filter messages they don't
 * care about.
 */
export const KEY_PREFIX = {
  BLACKLIST: 'blacklist:',
  BDUI: 'bdui:',
  ROLES: 'roles:',
  RATELIMIT: 'ratelimit:',
} as const;

export const CHANNEL = {
  BDUI_INVALIDATE: 'bdui:invalidate',
  ROLES_INVALIDATE: 'roles:invalidate',
} as const;

export const TTL_SECONDS = {
  BDUI: 300, // 5 min — architecture line 224-228
  ROLES: 300, // mirror RolesService in-memory TTL
  ACCESS_MAX: 900, // 15 min — JWT access token max blacklist ttl
} as const;

export const BDUI_COMPRESS_THRESHOLD_BYTES = 10 * 1024;
export const BDUI_L1_MAX_ENTRIES = 100;
export const BDUI_L1_TTL_MS = 60_000;
