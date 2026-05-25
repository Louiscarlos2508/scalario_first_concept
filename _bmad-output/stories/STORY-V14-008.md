# STORY-V14-008 : i18n complet ARB FR/EN + lint `no_hardcoded_strings`

**Epic :** EPIC-V14-004 — i18n (Phase 1 obligatoire)
**Priorité :** Must Have
**Story Points :** 5
**Status :** defined
**Sprint :** v14-3 (2026-06-23 → 2026-07-06)
**Dépendances :** V14-001 (nomenclature)

---

## User Story

> **En tant que** dev Scalario,
> **je veux** que **toute string visible** par l'utilisateur passe par les ARB files FR/EN, et qu'un lint custom rejette automatiquement tout `Text('hello')` hardcodé,
> **so that** ouvrir un nouveau pays = ajouter une langue, pas refactorer 50 écrans. v14 §8b dit que c'est OBLIGATOIRE dès Phase 1.

---

## Description

### Background

J'avais différé i18n complet dans STORY-042 v13 (uniquement les `i18n_key` déclarées dans le catalogue, pas de ARB files complets ni de lint). v14 §8b est clair : "i18n ARB files FR/EN + lint no_hardcoded_strings dès le premier commit". À débloquer Phase 1.

### Scope

**In scope :**
- `apps/flutter/pubspec.yaml` : ajout `flutter_localizations` (sdk) + `intl: ^0.19+` + `flutter gen-l10n` config
- `apps/flutter/l10n.yaml` configuré
- `apps/flutter/lib/l10n/app_fr.arb` complet (100% des clés référencées dans le catalogue v14)
- `apps/flutter/lib/l10n/app_en.arb` ≥ 60% (toutes navigation, rôles, modules, screens titles)
- `S.of(context).<key>` partout dans `lib/features/` et `lib/screens/` (0 string hardcodée)
- Lint custom `no_hardcoded_strings_in_widgets` actif dans `analysis_options.yaml`
- LocaleProvider Riverpod résout depuis `tenant.config.locale`
- Helper `Currency.format(amount, tenant)` (déjà livré STORY-042) intégré aux ARB pour `montantXof` placeholder

**Out of scope :**
- ARB Bambara/Wolof/Dioula/Haoussa/Arabe — Phase 2 (V14 backlog) ou Phase 3
- Traduction automatique DeepL/Claude pour les clés manquantes — V14-019 (Scalario Forge)

---

## Acceptance Criteria

### Setup i18n

- [ ] **AC-01** — `pubspec.yaml` déclare `flutter_localizations` SDK + `intl: ^0.19+`.
- [ ] **AC-02** — `l10n.yaml` configuré (output-class S, template-arb-file app_fr.arb).
- [ ] **AC-03** — `MaterialApp` câblé avec `localizationsDelegates` + `supportedLocales: [Locale('fr','BF'), Locale('en','US')]`.
- [ ] **AC-04** — `LocaleProvider` Riverpod résout depuis `tenant.config.locale` au login (défaut `fr-BF`).

### ARB files

- [ ] **AC-05** — `app_fr.arb` contient 100% des clés référencées dans `catalog/` (script `scripts/extract-i18n-keys.ts` extrait les clés depuis tous les `*.json`).
- [ ] **AC-06** — `app_en.arb` couvre ≥ 60% des clés (navigation, rôles, modules names, screens titles, messages communs).
- [ ] **AC-07** — Placeholders typés : `montantXof: "{montant} XOF"`, `stockRupture: "Rupture de stock : {produit}"`, etc.
- [ ] **AC-08** — Espace insécable préservé en FR (`12 500 FCFA` rendu via `intl.NumberFormat`).

### Lint `no_hardcoded_strings`

- [ ] **AC-09** — `analysis_options.yaml` ajoute le plugin `custom_lint` avec règle `no_hardcoded_strings`.
- [ ] **AC-10** — La règle détecte `Text('...')`, `Tooltip(message: '...')`, `Semantics(label: '...')` non passés par AppLocalizations dans `lib/features/` et `lib/screens/`.
- [ ] **AC-11** — Exception via commentaire annoté : `// i18n-ignore: <reason>` ou `// bdui-engine: <reason>`.
- [ ] **AC-12** — Whitelist : `lib/core/`, `*.g.dart` exclus.

### Tests + CI

- [ ] **AC-13** — `flutter analyze` = 0 issue sur tout `lib/features/` et `lib/screens/`.
- [ ] **AC-14** — Test E2E : changement de locale runtime (`fr-BF` → `en-US`) → tous les labels visibles se mettent à jour sans restart app.
- [ ] **AC-15** — Test : un clé i18n manquante en EN → fallback FR (pas crash).
- [ ] **AC-16** — Script `scripts/check-i18n-coverage.ts` qui rapporte le % de couverture FR/EN par module/screen.

---

## Technical Notes

### Structure des ARB

```
apps/flutter/lib/l10n/
├── app_fr.arb              ← Français (référence — 100%)
├── app_en.arb              ← Anglais (60%+ obligatoire)
└── README.md               ← Convention de naming des clés
```

### Exemple `app_fr.arb`

```json
{
  "@@locale": "fr",
  "welcomeMessage": "Bienvenue sur Scalario",
  "@welcomeMessage": { "description": "Message accueil login" },
  "commandesTitle": "Commandes",
  "validerCommande": "Valider la commande",
  "stockRupture": "Rupture de stock : {produit}",
  "@stockRupture": {
    "placeholders": { "produit": { "type": "String" } }
  },
  "montantXof": "{montant} XOF",
  "@montantXof": {
    "placeholders": { "montant": { "type": "num", "format": "decimalPattern" } }
  }
}
```

### Lint custom — implementation

```yaml
# analysis_options.yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  rules:
    - no_hardcoded_strings:
        whitelist_dirs:
          - lib/core/
          - lib/bdui/
        whitelist_files:
          - "*.g.dart"
        annotation_ignore: "i18n-ignore"
```

Une règle Dart simple qui :
1. Détecte les expressions `Text(StringLiteral)`, `Tooltip(message: StringLiteral)`, `Semantics(label: StringLiteral)`, `AppBar(title: Text(StringLiteral))`
2. Vérifie si dans whitelist ou annoté
3. Sinon → erreur `flutter analyze`

### Edge cases

- String dynamique (template avec `$var`) → autoriser via heuristique (start avec `$`, contient `${`)
- IDs et URLs → autoriser (regex courant)
- Strings de debug (`developer.log`, `print`) → autoriser
- Strings de test (`expect`, `equals`) → autoriser

---

## Dependencies

- **Prérequis :** V14-001 (nomenclature), V14-006 (catalog restructure pour extract-i18n-keys)
- **Stories bloquées :** V14-019 (Scalario Forge consomme les ARB pour générer des `label_key`)

---

## Definition of Done

- [ ] Setup i18n complet (pubspec, l10n.yaml, MaterialApp)
- [ ] `app_fr.arb` 100% + `app_en.arb` 60%+
- [ ] Lint `no_hardcoded_strings` actif, 0 erreur
- [ ] LocaleProvider Riverpod fonctionnel
- [ ] Script extract-i18n-keys.ts + check-i18n-coverage.ts livrés
- [ ] Memory `feedback_scalario_i18n_v14.md` (règles ARB + lint)
- [ ] sprint-status.yaml V14-008 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Setup flutter_localizations + l10n.yaml | 0.5 |
| ARB files FR 100% + EN 60% (~200-300 clés) | 1.5 |
| Lint custom `no_hardcoded_strings` | 1.5 |
| LocaleProvider Riverpod | 0.5 |
| Scripts extract + coverage check | 0.5 |
| Tests + docs | 0.5 |
| **Total** | **5** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
