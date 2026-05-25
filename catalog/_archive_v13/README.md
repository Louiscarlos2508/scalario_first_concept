# `catalog/_archive_v13/` — Sauvegarde de la v13

**Créé par STORY-V14-006 (2026-05-25).** Conserve les fichiers v13 du catalogue après refonte v14, pour traçabilité et référence audit (cf STORY-AUDIT-v14.md).

## Contenu

| Fichier | Provenance v13 | Rôle |
|---|---|---|
| `domains/retail_fresh_produce.json` | `catalog/domains/retail_fresh_produce.json` | Template "fresh produce" v13 (Blandine) — toujours chargeable via les loaders v14 (fallback) |
| `modules/module_dashboard_owner.json` | `catalog/modules/` | Dashboard owner v13 — STORY-040 |
| `modules/module_dashboard_manager.json` | `catalog/modules/` | Dashboard manager v13 — STORY-040 |
| `modules/module_dashboard_commercial.json` | `catalog/modules/` | Dashboard commercial v13 — STORY-040 |
| `modules/module_ventes.json` | `catalog/modules/` | Module ventes v13 — STORY-040 |
| `modules/module_pertes.json` | `catalog/modules/` | Module pertes v13 — STORY-040 |
| `modules/module_stock.json` | `catalog/modules/` | Module stock v13 — STORY-040 |

## Backward compatibility

Les loaders NestJS v14 (`module-resolver.service.ts`, `catalogue-loader.service.ts`, `templates.loader.ts`) ont été étendus pour **chercher en fallback** dans `_archive_v13/` quand un fichier n'est pas trouvé dans la nouvelle structure.

Ça permet :
- Aux tests existants (STORY-040, STORY-043) de continuer à passer
- Aux ERP en prod basés sur le template `retail_fresh_produce` de continuer à fonctionner
- À V14-007 de migrer progressivement les 6 modules génériques v14 sans casser les v13

## Quand supprimer

Ce dossier sera supprimé quand :
1. V14-007 aura livré les 6 modules génériques v14 (`modules/<gestion|finance|rh|operations>/*.json`)
2. Le template `retail_fresh_produce` sera redécomposé en composition de modules v14
3. Aucun test ne référence plus `_archive_v13/`

À ce moment-là, `git rm -r catalog/_archive_v13/` + retrait des fallbacks dans les loaders.

## Liens

- Story de création : `_bmad-output/stories/STORY-V14-006.md`
- Audit v13→v14 : `_bmad-output/architecture-v14/stories-audit/STORY-AUDIT-v14.md`
