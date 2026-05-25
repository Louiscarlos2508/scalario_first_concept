# STORY V14-002 — JSON Schema BDUI + champ `variant`

**Phase :** 1 — Fondations
**Bloc :** Scalario Canvas
**Story Points :** 3
**Status :** defined
**Created :** 2026-05-25
**Dépendances :** S23 (JSON Schema BDUI v1.0.0)

---

## User Story

> **En tant qu'**intégrateur Scalario certifié (Phase 1) ou Config Agent IA (Phase 2+),
> **je veux** que le `ComponentConfig` JSON expose un champ `variant` qui prend des valeurs nommées (`default`, `compact`, `with-icon`, `hero`, `with-chart`, `auto`),
> **so that** un même composant DS (KPICard, DataTable…) peut être rendu sous N apparences contextuelles sans dupliquer N types dans le registre.

---

## Contrat JSON v14

```typescript
interface ComponentConfig {
  schema_version: '1.0.0';
  type: string;           // 'KPICard' | 'DataTable' | ... (registre fermé)
  variant: string;        // 'default' | 'compact' | 'auto' | ... (par composant)
  id?: string;            // Pour les refs visible_if
  props: Record<string, unknown>;
  visible_if?: Rule;
  source?: DataSource;
  validation?: ValidationRule[];
  actions?: ActionStep[];     // ← NOUVEAU v14 — pipelines déclenchés
  children?: ComponentConfig[]; // ← NOUVEAU v14 — composition
  i18n_key?: string;
}
```

Trois changements vs v13 :

1. **`variant: string`** (NOUVEAU) — obligatoire. `default` par défaut. Validé par Scalario Profile qui déclare les variantes autorisées par métier.
2. **`actions?: ActionStep[]`** (NOUVEAU) — chaque composant peut déclarer une ou plusieurs actions à exécuter sur événement (`tap`, `submit`, `change`). Cf. Scalario Flow.
3. **`children?: ComponentConfig[]`** (NOUVEAU) — composition récursive de composants. Permet d'embedder un `Section` qui contient `KPICard + DataTable + Button`.

---

## Acceptance Criteria

### Schéma JSON Draft 2020-12

- [ ] AC-01 — `catalog/schemas/component-config.schema.json` mis à jour avec `variant: { "type": "string" }` (required: true).
- [ ] AC-02 — `actions` array de `ActionStep` (registry, fn, inputs, output, on_error).
- [ ] AC-03 — `children` array récursif de `ComponentConfig`.
- [ ] AC-04 — Validation : `variant` peut être `'auto'` (Flutter résout au runtime).
- [ ] AC-05 — Exemples mis à jour : `valid_with_variant.json`, `valid_with_actions.json`, `valid_with_children.json`.
- [ ] AC-06 — Test négatif : `variant: 123` (number) rejeté.

### Zod côté NestJS

- [ ] AC-07 — `component-config.zod.ts` accepte `variant: z.string().default('default')`.
- [ ] AC-08 — `actions: z.array(ActionStepZod).optional()`.
- [ ] AC-09 — `children: z.lazy(() => z.array(ComponentConfigZod)).optional()` (récursif).

### Validator Dart côté Flutter

- [ ] AC-10 — `ComponentConfigValidator` accepte les nouveaux champs.
- [ ] AC-11 — `ScalarioCanvasResolver.resolveVariant(variant, ctx)` retourne le variant effectif si `auto`.

### Tests

- [ ] AC-12 — `component-config.zod.spec.ts` : 6 cas (variant present, variant absent → default, variant 'auto', actions, children, négatifs).
- [ ] AC-13 — `component-config.zod.flutter.spec.dart` : équivalence parsing FR/EN.

---

## Migration des composants existants

Les ScreenConfigs déjà committés (catalog/modules/*.json) n'ont pas de champ `variant` — Zod le complétera avec `'default'` à la validation. Pas de migration data nécessaire.

---

## Definition of Done

- [ ] Schema JSON + Zod NestJS + Dart Flutter alignés
- [ ] 12 tests verts (6 Jest + 6 Dart)
- [ ] Documentation mise à jour : `catalog/README.md` section "variantes"
- [ ] Memory : `feedback_scalario_variants.md` (1 type + N variantes, variant: 'auto' choisi par Flutter)
