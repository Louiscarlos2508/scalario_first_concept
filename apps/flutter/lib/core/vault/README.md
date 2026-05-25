# Offline — Persistance locale Drift + SQLCipher

## Décision Drift vs Isar

| Critère | Drift | Isar |
|---|---|---|
| SQL typé | ✅ natif | ❌ NoSQL |
| Alignement schéma serveur (Postgres) | ✅ direct | ⚠ mapping manuel |
| Drift Web (IndexedDB) — STORY-038 | ✅ même API | ⚠ Isar Web expérimental |
| Migrations versionnées | ✅ MigrationStrategy | ✅ |
| Performance read | ⚡ < 30ms (cible OK) | ⚡⚡ |
| Écosystème, support communauté | ✅ mature | ⚠ moins large |

**Décision : Drift.** Le critère bloquant est la cross-platform mobile + web (STORY-038)
avec exactement la même API et le même schéma. Isar Web 2026 reste expérimental.

## Schéma

5 tables core :

| Table | Rôle | PK |
|---|---|---|
| `tenant_configs` | Config tenant chiffrée + métadonnées | `tenantId` |
| `cached_layouts` | Screen configs BDUI + ETag | `screenId` |
| `local_data` | Entités métier en JSONB local | `id` (UUID) |
| `sync_queue_items` | Queue de mutations à synchroniser | `mutationId` (UUID) |
| `conflicts` | Conflits de sync (squelette STORY-035) | `id` |

## Chiffrement

- SQLCipher AES-256 activé au premier lancement.
- Passphrase 32 bytes base64 générée aléatoirement, stockée dans `flutter_secure_storage`.
- JWT Access/Refresh **jamais** dans Drift — `flutter_secure_storage` exclusivement.

## Architecture

```
lib/core/offline/
├── database.dart           # ScalarioDatabase (Drift DB)
├── tables/                 # Définitions des tables Drift
├── dao/                    # Data Access Objects typés
├── local_store.dart        # Façade singleton pour le reste de l'app
├── cache_cleaner.dart      # LRU sur cached_layouts
├── bootstrap_service.dart  # Bootstrap initial (online obligatoire)
├── drift_data_source_resolver.dart  # Implémente DataSourceResolver via Drift
└── README.md               # Ce fichier
```
