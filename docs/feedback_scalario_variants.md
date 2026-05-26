# feedback_scalario_variants.md — Memoire Variantes Scalario Canvas

**Date** : 2026-05-25
**Story** : STORY-V14-002 (JSON Schema BDUI v1.1.0)
**Auteur** : Carlos + Claude

## Principe "1 type + N variantes"

Un composant DS (ex: `KPICard`) peut etre rendu sous N variantes sans creer N types separes dans le registre.
La variante est resolue au moment du rendu par `ComponentConfig.variant`.

## Variantes definies (Phase 1)

| Variante | Comportement | Contexte typique |
|---|---|---|
| `default` | Rendu standard | Fallback universel |
| `auto` | Resolution automatique | Laisse Flutter decider selon le contexte |
| `compact` | Vue reduite, 1 ligne | KPICard dans Row, petits ecrans |
| `hero` | Vue large, proeminente | Dashboard OWNER grand ecran |

## Resolution `auto`

`ScalarioCanvasResolver.resolveVariant(variant, ctx)` :
1. `variant != 'auto'` → retourne tel quel (pass-through)
2. `context == null` → `'default'`
3. `width < 360` OU `(role == 'COMMERCIAL' && childCount > 3)` → `'compact'`
4. `width >= 900 && role in {'OWNER', 'SUPER_ADMIN'}` → `'hero'`
5. Sinon → `'default'`

Cette heuristique Phase 1 sera etendue dans V14-004 (catalogue des variantes par composant).

## Contexte de resolution

`VariantContext` :
- `screenWidth: double` — largeur ecran en pixels logiques
- `userRole: String` — role de l'utilisateur (OWNER, MANAGER, COMMERCIAL, SUPER_ADMIN)
- `childCount: int` — nombre d'enfants du parent direct (default 0)

## Actions pipeline

Chaque composant peut declencher un pipeline d'actions vers les engines Scalario :
- `canvas` — navigation, overlay, toasts
- `form` — validation, soumission
- `calc` — formules, transformations
- `sense` — scan, GPS, camera, print BT, Mobile Money
- `vault` — CRUD, queries
- `live` — websocket, notifications

## Composition recursive

`children: ComponentConfig[]` permet :
- `Section > Row > [KPICard, DataTable]`
- `FormSection > [TextField, Dropdown, Button]`
- Profondeur max : 5 niveaux (anti-abuse)

## Fichiers cles

| Fichier | Role |
|---|---|
| `catalog/schemas/component-config.schema.json` | JSON Schema v1.1.0 |
| `apps/nestjs/src/catalog-loader/validators/component-config.zod.ts` | Zod NestJS |
| `apps/flutter/lib/engine/canvas_registry/component_config.dart` | Dart model + resolver |
| `catalog/schemas/examples/component-config/` | 10 examples (4 v1.0.0 + 6 v1.1.0) |
