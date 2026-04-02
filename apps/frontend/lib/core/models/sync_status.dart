// Fix 3 — `failed` est un état terminal (>= maxRetries tentatives réseau/5xx).
// Contrairement à `error` (réinitialisé par resetErrorOrders au refresh token),
// `failed` nécessite une action explicite de l'admin via l'écran diagnostic.
// Stocké par nom (EnumType.name) — migration additive, aucun index Isar impacté.
enum SyncStatus { pending, synced, error, failed }
