/**
 * Version du schéma POS sync.
 *
 * Incrémenter ce numéro à chaque migration Prisma qui affecte les collections
 * synchronisées sur le device (CatalogItem, Category, Contact/Customer).
 *
 * Le client Flutter compare ce numéro avec sa version locale stockée en Isar.
 * En cas de divergence, il force un re-provisioning complet (full pull)
 * au lieu de tenter de parser des données potentiellement incompatibles.
 *
 * ## Historique
 * 1 — Schéma initial (2026-04-02)
 */
export const POS_SCHEMA_VERSION = 1;
