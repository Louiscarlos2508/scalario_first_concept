# `catalog/ux_profiles/` — UX par métier (Scalario Profile)

**Créé par STORY-V14-006.** Définit les **règles UX par secteur** : variants de composants autorisés, layouts, patterns d'interaction, terminologie.

## Sous-dossiers

| Dossier | Cible |
|---|---|
| `_base/` | Règles communes héritées par tous les secteurs (components.json, layout_rules.json, ux_patterns.json) |
| `commerce_general/` | Petit commerce (épicerie, vente détail) — UX simple, dense, mobile-first |
| `pharmacie/` | Officine — scanner code-barres + alerte péremption visibles |
| `btp/` | Construction — fiches chantier + GPS + photos |
| `cabinet_medical/` | Médecin/dentiste — agenda + dossier patient |

## Format

Chaque profile est validé par `catalog/schemas/ux-profile.schema.json` + loader `apps/nestjs/src/catalog-loader/loaders/ux-profile-loader.ts`.

Exemple :
```json
{
  "schema_version": "1.0.0",
  "profile_id": "pharmacie",
  "sector": "pharmacie",
  "inherits": ["_base"],
  "variants_allowed": {
    "KPICard": ["compact", "expanded", "auto"],
    "DataTable": ["dense", "auto"]
  },
  "layout_rules": {
    "max_kpis_per_row": 4,
    "default_density": "compact",
    "primary_action_position": "bottom_right_fab"
  },
  "naming_conventions": {
    "transaction": "vente",
    "item": "médicament",
    "container": "boîte"
  }
}
```

## Héritage `inherits`

Un profile peut référencer plusieurs parents (résolu au boot, merge profond). `_base` est implicite si non listé.

## Phase 1 vs Phase 2

- **Phase 1** : structure créée, dossiers vides. Loader stub fonctionnel.
- **Phase 2** (V14-004) : implémentation `_base/` + 4 profiles sectoriels.

## Liens

- Story Phase 2 : `_bmad-output/stories/STORY-V14-004.md`
- Schema : `catalog/schemas/ux-profile.schema.json`
