# STORY-006 : RuleEvaluator

**Epic :** EPIC-002 — BDUI Engine Flutter
**Priorité :** Must Have
**Story Points :** 5
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 1 (2026-05-12 → 2026-05-23)
**Dependencies :** STORY-023 (JSON Schema pour types `Rule`) — peut être en parallèle ; STORY-009 (Auth JWT) seulement pour la source du `UserContext` runtime, mais le RuleEvaluator lui-même est indépendant de l'auth en termes de code

---

## User Story

> **En tant que** BDUIEngine Scalario,
> **je veux** un évaluateur pur qui prend une expression `Rule` JSON (`visible_if`, `enabled_if`, `required_if`) et un `UserContext` et retourne un booléen,
> **so that** chaque composant se masque, se désactive ou devient requis selon le rôle / les attributs sans aucun `if` métier dans le code Flutter.

---

## Description

### Background

Le principe non-négociable de Scalario est : **zéro logique métier dans le code Flutter** (cf. PRD §FR-001 ligne 246, architecture ligne 34). Toute condition d'affichage, d'activation ou d'exigence d'un champ doit être déclarée en JSON et évaluée au runtime.

Trois types de règles vivent côte à côte dans le contrat partagé (`architecture` ligne 965) :

- `visible_if` — affiche/masque un composant entier.
- `enabled_if` — active/désactive un input ou un bouton.
- `required_if` — rend un champ de formulaire obligatoire conditionnellement (consommé par STORY-011).

Le **RuleEvaluator** est la fonction pure qui répond à ces trois questions. Une seule classe, trois cas d'usage. Elle n'a aucune dépendance Flutter (pas de `BuildContext`), aucune I/O (pas de DB, pas de réseau), aucun état mutable. Elle est testable à 100% en isolation.

Phase 1 = **RBAC uniquement** : `role`, `==`, `!=`, `>`, `<`, `AND`, `OR`. Phase 2 ajoutera ABAC (attributs contextuels comme `tenant.feature_flags`, `entity.owner_id == user.id`).

### Scope

**In scope :**

- Package `lib/engine/rule_evaluator/` avec :
  - `rule.dart` — value object DTO `Rule` conforme au contrat partagé.
  - `user_context.dart` — `UserContext` immutable (`userId`, `tenantId`, `roles: Set<String>`, `departmentId`, `attributes: Map<String, dynamic>`).
  - `rule_evaluator.dart` — classe `RuleEvaluator` avec méthodes pures `evaluate(rule, ctx, [recordData])`.
  - `rule_parser.dart` — `Rule.fromJson` qui valide la structure et lève `RuleParseException` sur format incorrect.
- Opérateurs supportés :
  - **Logiques :** `AND`, `OR`, `NOT` (ajout par rapport au sprint plan — utile pour `required_if`).
  - **Identité :** `role` (alias raccourci pour `userCtx.roles.contains(value)`).
  - **Comparaison :** `==`, `!=`, `>`, `<`, `>=`, `<=`.
  - **Appartenance :** `in`, `not_in` (ex : `{ "field": "status", "operator": "in", "value": ["draft", "pending"] }`).
- Résolveur de chemins de champ (`resolveField`) : supporte `user.role`, `user.attributes.foo`, `record.montant`, `record.lines[0].qty` (notation pointée + index).
- Performance : évaluation **< 1ms par composant** sur Snapdragon 680, mesurée par benchmark unit test.
- Tests exhaustifs : 25+ cas couvrant tous les opérateurs, imbrications, edge cases.
- Documentation inline avec exemples JSON pour chaque opérateur.

**Out of scope (autres stories) :**

- Récupération du `UserContext` depuis JWT → STORY-009 (Auth) injecte un Provider lu ici via DI ; cette story expose juste l'interface.
- ABAC complet (resource-based) → Phase 2.
- Évaluation côté backend (NestJS) — c'est le `BDUIService` qui filtre côté serveur avec un évaluateur miroir TypeScript ; pas dans cette story Flutter.
- Application des règles à des composants concrets → STORY-008 (BDUIEngine) consomme le RuleEvaluator.
- UI feedback (champs grisés, asterisques rouges) → STORY-011.
- Cache d'évaluation → si nécessaire, ajouté en STORY-008 (par exemple memoize sur `(ruleHash, userCtxHash)`).

### Runtime Flow

1. BDUIEngine parse un `ScreenConfig`, itère les `ComponentConfig`.
2. Pour chaque `config`, l'Engine appelle `evaluator.evaluate(config.visibleIf, userCtx)`.
3. `evaluate` reçoit la `Rule` (potentiellement null), retourne `bool`.
4. Si `false`, l'Engine n'instancie pas le composant (court-circuit avant `ComponentRegistry.build`).
5. Pour `enabled_if` (sur ActionButton, TextInput, etc.), même appel — résultat passé en prop au widget DS.
6. Pour `required_if` (sur FormSection field), même appel — résultat injecté dans le validator (STORY-011).
7. **Ordre d'évaluation :** d'abord `visible_if` (court-circuit total), puis `enabled_if` (composant rendu mais grisé), puis `required_if` (composant rendu, actif, mais validation conditionnelle).

---

## Acceptance Criteria

### Modèle de données

- [ ] AC-01 — Classe immutable `Rule` avec champs : `operator: String`, `children: List<Rule>?`, `field: String?`, `value: dynamic` (peut être `String`, `num`, `bool`, `List`, `null`). `==` + `hashCode` corrects pour memoization.
- [ ] AC-02 — `Rule.fromJson(Map<String, dynamic>)` parse les 3 formes :
  - **Composée :** `{ "AND": [ {...}, {...} ] }` ou `{ "OR": [...] }` ou `{ "NOT": {...} }`.
  - **Comparaison de champ :** `{ "field": "montant", "operator": ">", "value": 500000 }`.
  - **Raccourci role :** `{ "role": ["MANAGER", "DG"] }` (équivalent à `{ "field": "user.role", "operator": "in", "value": [...] }`).
- [ ] AC-03 — JSON malformé (operator inconnu, children manquants pour AND/OR, field manquant pour comparaison) → `RuleParseException` avec message clair indiquant le chemin du nœud fautif.
- [ ] AC-04 — Classe immutable `UserContext` avec champs : `userId: String`, `tenantId: String`, `roles: Set<String>`, `departmentId: String?`, `attributes: Map<String, dynamic>`. Constructible depuis JWT claims.

### Opérateurs logiques

- [ ] AC-05 — `evaluate(null, ctx) → true` (composant sans `visible_if` toujours visible).
- [ ] AC-06 — `AND` : retourne `true` ssi **tous** les enfants évaluent à `true`. Court-circuit dès le premier `false`.
- [ ] AC-07 — `OR` : retourne `true` ssi **au moins un** enfant évalue à `true`. Court-circuit dès le premier `true`.
- [ ] AC-08 — `NOT` : prend exactement 1 enfant (pas une liste), retourne l'inverse. `{ "NOT": { "role": ["GUEST"] } }`.
- [ ] AC-09 — `AND` ou `OR` avec liste vide → `RuleParseException` (interdit ; sémantique ambiguë).

### Opérateur role + comparaison

- [ ] AC-10 — `{ "role": ["MANAGER"] }` → `true` ssi `userCtx.roles.contains("MANAGER")`.
- [ ] AC-11 — `{ "role": ["MANAGER", "DG"] }` → `true` ssi `userCtx.roles` intersecte la liste.
- [ ] AC-12 — `==`, `!=` : égalité Dart standard, fonctionne pour `String`, `num`, `bool`, `null`.
- [ ] AC-13 — `>`, `<`, `>=`, `<=` : opèrent sur `num` (int + double). Si types non-numériques → `false` + warning log (pas d'exception).
- [ ] AC-14 — `in` / `not_in` : `value` doit être une `List`. `{ "field": "status", "operator": "in", "value": ["draft", "pending"] }`.

### Résolution de champs

- [ ] AC-15 — `resolveField("user.role")` retourne `userCtx.roles.first` (ou `null` si vide).
- [ ] AC-16 — `resolveField("user.attributes.feature_flag_xyz")` lit `userCtx.attributes['feature_flag_xyz']`. Notation pointée arbitrairement profonde.
- [ ] AC-17 — `resolveField("record.montant", recordData)` lit `recordData['montant']` quand `recordData` est passé à `evaluate`. Sans `recordData` fourni, `record.*` retourne `null` + warning log.
- [ ] AC-18 — Notation index : `resolveField("record.lines[0].qty")` supporte les listes. Index out of bounds → `null` (pas d'exception).
- [ ] AC-19 — Champ absent → `null`. Le `null` se compare comme attendu (`null == null → true`, `null > 0 → false`).

### Performance

- [ ] AC-20 — Benchmark unit test : évaluation d'une `Rule` imbriquée à 5 niveaux de profondeur sur un `UserContext` à 10 attributs prend **< 1ms** sur émulateur Snapdragon 680 (CI matrix). Test échoue si dépassement ≥ 5 fois consécutives sur 1000 itérations.
- [ ] AC-21 — Aucune allocation transitoire dans le hot path (`evaluate` ne crée pas de nouvelles `List` ni `Map` — itération directe).
- [ ] AC-22 — `RuleEvaluator` est un `@immutable` value object — instance unique injectable via DI, pas de state mutation entre appels.

### Tests

- [ ] AC-23 — 25+ tests unitaires couvrant :
  - Chaque opérateur isolé (10 ops).
  - Imbrications AND(OR(NOT)) à 4+ niveaux.
  - Rôle inconnu, rôle vide.
  - Comparaisons avec `null`, types mismatchés.
  - Champs `user.*`, `record.*`, attributs profonds, index list.
  - JSON malformé (operator inconnu, children manquants, field absent) → exception avec message.
  - Le retail_dashboard fixture entier avec un `MANAGER` vs un `CASHIER` → screens différents rendus correctement (test d'intégration léger en pure Dart, pas Flutter widget test).
- [ ] AC-24 — Couverture ≥ 95% sur `lib/engine/rule_evaluator/` (Gate 0 stricte pour l'Engine).
- [ ] AC-25 — Aucun `if` lié à un domaine métier dans `lib/engine/rule_evaluator/` (vérifié par grep CI : pas de `MANAGER`, `OWNER`, `tenant_id` codé en dur — tout vient des arguments).

---

## Technical Notes

### Composants concernés

- **Nouveau package :** `apps/flutter/lib/engine/rule_evaluator/`
- **Pure Dart :** zéro dépendance Flutter dans `lib/engine/rule_evaluator/`. Vérifié par lint CI (`import 'package:flutter/...'` interdit dans ce dossier).
- **DI :** `RuleEvaluator` enregistré via `get_it` au démarrage par `RegistryBootstrap` ou un nouveau `EngineBootstrap`.

### Structure de fichiers (cible)

```
apps/flutter/
├── lib/
│   └── engine/
│       └── rule_evaluator/
│           ├── rule.dart                 # Rule + Rule.fromJson + RuleParseException
│           ├── user_context.dart         # UserContext immutable
│           ├── rule_evaluator.dart       # RuleEvaluator.evaluate()
│           ├── field_resolver.dart       # resolveField(path, ctx, [record])
│           └── rule_evaluator.dart       # barrel export
├── test/
│   └── engine/
│       └── rule_evaluator/
│           ├── rule_parser_test.dart
│           ├── operator_logical_test.dart      # AND/OR/NOT
│           ├── operator_comparison_test.dart   # ==/!=/>/<...
│           ├── operator_role_test.dart
│           ├── field_resolver_test.dart
│           ├── benchmark_test.dart             # < 1ms enforce
│           └── fixtures/
│               └── retail_dashboard_visibility.json
```

### Pattern Dart recommandé

```dart
@immutable
final class Rule {
  const Rule({
    required this.operator,
    this.children,
    this.field,
    this.value,
  });

  final String operator;
  final List<Rule>? children;
  final String? field;
  final Object? value;

  factory Rule.fromJson(Map<String, dynamic> json) { /* ... */ }

  @override
  bool operator ==(Object other) => /* deep equals */;

  @override
  int get hashCode => /* combined */;
}

@immutable
final class UserContext {
  const UserContext({
    required this.userId,
    required this.tenantId,
    required this.roles,
    this.departmentId,
    this.attributes = const {},
  });

  final String userId;
  final String tenantId;
  final Set<String> roles;
  final String? departmentId;
  final Map<String, Object?> attributes;
}

@immutable
final class RuleEvaluator {
  const RuleEvaluator();

  bool evaluate(
    Rule? rule,
    UserContext userCtx, [
    Map<String, Object?>? recordData,
  ]) {
    if (rule == null) return true;
    return switch (rule.operator) {
      'AND' => rule.children!.every(
        (child) => evaluate(child, userCtx, recordData),
      ),
      'OR' => rule.children!.any(
        (child) => evaluate(child, userCtx, recordData),
      ),
      'NOT' => !evaluate(rule.children!.first, userCtx, recordData),
      'role' => _evaluateRole(rule.value, userCtx),
      '==' || '!=' || '>' || '<' || '>=' || '<=' || 'in' || 'not_in' =>
          _evaluateComparison(rule, userCtx, recordData),
      _ => _logUnknownAndDefault(rule.operator),
    };
  }
}
```

### Spec source — résolution du conflit PRD ↔ sprint plan

Le sprint plan (ligne 176) liste les opérateurs `AND`, `OR`, `role`, `>`, `<`, `==`. **Cette liste est minimale.** Le PRD §FR-002 (ligne 219) liste les mêmes. Mais STORY-011 (Validation forms) requiert `required_if`, qui demande typiquement `NOT`, `!=`, `in`, `>=`, `<=` pour exprimer "obligatoire si payment_method != cash" ou "obligatoire si stock_quantity <= 5".

**Décision :** étendre l'ensemble d'opérateurs à : `AND`, `OR`, `NOT`, `role`, `==`, `!=`, `>`, `<`, `>=`, `<=`, `in`, `not_in`. Cette extension est rétrocompatible (les règles PRD existantes restent valides) et évite de retoucher le RuleEvaluator quand STORY-011 arrive en sprint 1 aussi. **DS / besoins downstream gagnent**.

### Edge cases

- **`field` absent dans le record** : `resolveField` retourne `null`. Comparer `null > 0` retourne `false` ; `null == null` retourne `true`. C'est le comportement attendu — un champ manquant ne doit jamais cacher quelque chose qui devrait être visible (fail-safe : default visible).
- **Récursion infinie** : la profondeur max de récursion est bornée par la profondeur du JSON. JSON Schema (STORY-023) doit imposer une limite (ex: depth ≤ 10) pour éviter un DoS sur l'évaluateur. Documenter en commentaire ; pas implémenté ici.
- **Type mismatch** (ex: `{ "field": "name", "operator": ">", "value": 5 }` quand `name` est un `String`) : retourne `false` + log warning. Pas d'exception — un screen ne doit pas crash sur une règle mal écrite.
- **`role` avec valeur non-liste** (ex: `{ "role": "MANAGER" }`) : accepter les deux formes `String` et `List<String>`. Convertir un `String` en `[String]` à la volée.
- **Attributs sensibles dans `UserContext`** : ne jamais y mettre le mot de passe ni le token JWT — uniquement les claims publics. Documenté dans la doc de classe.

### Sécurité

- **Trust boundary :** le RuleEvaluator s'exécute côté **client**. Une règle peut être bypassée par un utilisateur malveillant qui modifie le JSON localement. **C'est attendu** : la véritable sécurité est côté backend (FR-010 RBAC Guards + RLS Postgres). Le RuleEvaluator est une optimisation UX (ne pas afficher ce qui sera de toute façon refusé), pas une couche de sécurité.
- **Documentation explicite** : commentaire en tête de `rule_evaluator.dart` :
  ```dart
  // SECURITY: Le RuleEvaluator filtre l'UI côté client. Il N'EST PAS une
  // garantie de sécurité. Toute action protégée par visible_if doit AUSSI
  // être protégée côté backend (FR-010, FR-011, FR-012). Voir architecture
  // ligne 858 (NFR-003 Isolation Multi-tenant).
  ```
- **Pas de `eval`, pas de `dart:mirrors`** — l'évaluateur traite les expressions comme des données, pas du code.

### Performance

- HashMap lookups, court-circuit logique, pas d'allocation transitoire — l'évaluation reste O(n) avec n = nombre de nœuds dans la `Rule`. Pour une règle typique (3-5 nœuds), c'est < 0.1ms.
- Benchmark CI matrix (Android emulator Snapdragon 680) — alerte si > 1ms.
- Memoization : pas implémentée ici. Si l'Engine STORY-008 mesure un coût significatif sur des screens à 30+ composants, ajouter un cache `(ruleHash, userCtxHash) → bool` dans l'Engine, pas dans l'évaluateur (qui reste pur).

---

## Dependencies

**Prérequis :**

- STORY-023 (JSON Schema partagé) — peut être en parallèle. Cette story implémente `Rule.fromJson` manuellement ; quand STORY-023 figera le schema, regénérer via quicktype.
- Aucune dépendance Flutter / runtime externe.

**Stories bloquées par celle-ci :**

- STORY-008 (BDUIEngine) — directe (consomme `evaluator.evaluate(visibleIf, ctx)` dans le pipeline).
- STORY-011 (Validation forms) — directe (consomme `evaluator.evaluate(requiredIf, ctx)` pour validation conditionnelle).
- STORY-039+ (Catalogue templates) — indirecte (les templates contiennent des règles que cet évaluateur lit).

**Externes :**

- Aucun.

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-006-rule-evaluator`.
- [ ] `flutter analyze` passe sans warning sur `lib/engine/rule_evaluator/`.
- [ ] `flutter test test/engine/rule_evaluator/` vert avec ≥ 95% coverage.
- [ ] Benchmark `< 1ms par composant` vérifié en CI sur émulateur Snapdragon 680.
- [ ] Aucun import `package:flutter/...` dans `lib/engine/rule_evaluator/` (vérifié par grep CI).
- [ ] Aucun nom de rôle hardcodé dans le dossier (`MANAGER`, `OWNER`, etc. sont des données runtime, pas des constantes).
- [ ] Code review passé (auto-review Carlos + `/codex review`).
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour par l'orchestrateur (STORY-006 status `completed`, completed_points sprint 1 += 5).

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| `Rule` + `RuleParseException` + `Rule.fromJson` | 1 | 3 formes JSON à parser, validation stricte, message d'erreur pointant le nœud. |
| `UserContext` immutable + tests d'égalité | 0.25 | Trivial. |
| `FieldResolver` (notation pointée + index) | 0.75 | Parsing du path, accès profond Map+List, edge cases. |
| `RuleEvaluator.evaluate` (12 opérateurs) | 1.5 | Logique pure, mais 12 cases du switch + court-circuit + comparaisons typées. |
| Tests unitaires (25+ cas) + benchmark | 1 | Le filet le plus important — sans tests, l'évaluateur n'est pas digne de confiance. |
| Lint CI (no Flutter import, no business name) | 0.25 | Script grep simple. |
| Documentation inline (exemples JSON par opérateur) | 0.25 | Indispensable pour les futurs templates IA. |
| **Total** | **5** | Fibonacci 5 — moderate, fondation. |

**Rationale :** La logique est pure, mais la combinatoire (12 opérateurs × edge cases × types mixtes) demande un filet de tests serré. L'évaluateur sera appelé **des dizaines de fois par render** (chaque composant a un `visible_if`), donc un bug ici se propage partout. On prend 5 points pour blinder, pas 3.

---

## Notes additionnelles

- **Évaluateur miroir TypeScript côté backend** : le BDUIService NestJS (FR-016) doit appliquer les mêmes règles **avant** d'envoyer le JSON au client (sinon un attaquant qui sniff le HTTP voit toute la config). Cette story livre l'évaluateur Dart ; le miroir TS sera livré dans EPIC-003 (STORY-016 ou similaire). Les deux doivent partager les mêmes opérateurs et la même sémantique — d'où le contrat partagé `packages/shared-contracts`.
- **Phase 2 ABAC :** ajouter des opérateurs `owner_eq_user`, `tenant_feature_enabled`, etc. Le pattern `switch (operator)` rend l'extension triviale.
- **Logging warnings :** utiliser `dart:developer log()` avec `name: 'BDUI.RuleEvaluator'` — ainsi en dev les warnings remontent dans DevTools, en prod ils peuvent être routés vers un sink local (STORY-010).
- **Pas de `null safety` permissive :** `Rule.value` est `Object?` typé non-nullable safe. Forcer le caller à comparer avec attention.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
