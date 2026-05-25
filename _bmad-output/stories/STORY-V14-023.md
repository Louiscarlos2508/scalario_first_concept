# STORY-V14-023 : Scalario Form — orchestrateur saisie temps réel (Calc + Sense + Vault + ABAC)

**Epic :** EPIC-V14-015 — Scalario Form
**Priorité :** Must Have
**Story Points :** 8
**Status :** defined
**Sprint :** v14-8 (Phase 2)
**Dépendances :** V14-011, V14-024, STORY-011 v13 (validation formulaires base)

---

## User Story

> **En tant qu'**utilisateur ERP saisissant un formulaire (nouvelle commande, fiche employé, déclaration perte),
> **je veux** que chaque frappe puisse déclencher un calcul (`AlgoEngine`), chaque scan déclenche le hardware (`CapabilityRegistry`), chaque recherche déclenche une requête data (`DataSourceRegistry`), et que les champs apparaissent/disparaissent selon mon rôle (ABAC),
> **so that** une commande de 10 lignes avec prix unitaire scanné par code-barres + total auto + remise visible seulement si MANAGER + alerte stock si insuffisant fonctionne **sans une ligne de Flutter métier** — tout depuis JSON.

---

## Description

### Background

PRD v14 §7 : "Le Scalario Form est l'engine sans lequel l'ERP ne peut pas recevoir de données. Ce n'est pas un simple composant UI — c'est un orchestrateur qui coordonne les 4 autres engines en temps réel pendant la saisie."

4 raisons d'être distinct (§7.3) :
1. Orchestre en TEMPS RÉEL — chaque frappe peut déclencher AlgoEngine, scan déclenche CapabilityRegistry
2. Propre state (values, validation, computed fields, dependencies)
3. Applique ABAC au niveau champ (visible/readonly/required selon rôle)
4. Seul point d'entrée des données utilisateur — toute donnée passe par sa validation avant pipeline submit

### Scope

**In scope :**
- `lib/core/form/scalario_form.dart` — widget Form orchestrateur
- `FormConfig` JSON schema : `fields[]`, `on_submit`, `dependencies`
- Field types : text, number, scan_or_search, currency, date, select, computed
- Live calculation : si field.formula → AlgoEngine.eval at each change
- Capability : `field.capability = 'scanner'` → bouton scan ouvre caméra (Scalario Sense)
- DataSource : `field.datasource = { source: 'produits', search_on: ['nom','qr_code'] }` → autocomplete
- ABAC `visible_if`, `readonly_if` par champ
- Submit pipeline (`on_submit: { pipeline: 'creer_commande' }` → Scalario Flow)
- Tests : formulaire commande avec 6 fields (scan produit, qté, prix auto, remise visible MANAGER+, total live, stock alerte)

**Out of scope :**
- Hardware capabilities détails (V14-024)
- Mobile Money capability (V14-025)

---

## Acceptance Criteria

- [ ] **AC-01** — `ScalarioForm.fromConfig(formConfig, ctx)` rend les fields déclarés en JSON.
- [ ] **AC-02** — `formula` sur un field déclenche `AlgoEngine.eval` à chaque changement de dependency.
- [ ] **AC-03** — `capability: 'scanner'` ajoute bouton scan → ouvre Scalario Sense → résultat injecté dans field.
- [ ] **AC-04** — `datasource: { source, search_on }` ajoute autocomplete recherche → résultats Scalario Vault.
- [ ] **AC-05** — `visible_if: Rule` applique ABAC au runtime (champ disparaît si role insuffisant).
- [ ] **AC-06** — `readonly_if: Rule` rend le champ readonly (ABAC).
- [ ] **AC-07** — `validation: ValidationRule[]` validé live (message inline si erreur).
- [ ] **AC-08** — `on_submit: { pipeline }` POST l'event vers Scalario Flow.
- [ ] **AC-09** — Test : formulaire commande complet — scan produit, qty change → prix unit auto-fill, remise visible si MANAGER, total live, alerte stock si qty > stock_dispo.
- [ ] **AC-10** — Validation submit : si validation échoue → bloque submit, affiche erreurs en bas.

---

## Technical Notes

### Exemple FormConfig

```json
{
  "form_id": "nouvelle_commande",
  "fields": [
    { "id": "produit", "type": "scan_or_search",
      "capability": "scanner",
      "datasource": { "source": "produits", "search_on": ["nom","qr_code"] },
      "on_select": { "fill": { "prix_unitaire": "$produit.prix_vente" }, "output": "produit" } },
    { "id": "quantite", "type": "number",
      "validation": { "min": 1, "max": "$stock_dispo", "message_max": "Stock insuffisant" } },
    { "id": "remise", "type": "number",
      "visible_if": { "operator": "role", "value": ["MANAGER","DG"] },
      "validation": { "max": 20 } },
    { "id": "total_ttc", "type": "computed",
      "formula": { "fn": "mul", "args": ["$total_ht", 1.18] },
      "format": "currency_xof" }
  ],
  "on_submit": { "pipeline": "creer_commande" }
}
```

### State management

```dart
class ScalarioFormState extends ChangeNotifier {
  Map<String, dynamic> values = {};
  Map<String, String?> errors = {};
  Map<String, dynamic> computed = {};

  void onChange(String fieldId, dynamic value) {
    values[fieldId] = value;
    _recomputeDependents(fieldId);
    _revalidate(fieldId);
    notifyListeners();
  }

  void _recomputeDependents(String changedField) {
    for (final field in form.fields.where((f) => f.formula?.dependsOn(changedField) ?? false)) {
      computed[field.id] = AlgoEngine.eval(field.formula, values);
    }
  }
}
```

---

## Dependencies

- **Prérequis :** V14-011 (Scalario Calc), V14-024 (Scalario Sense), STORY-011 v13 (base validation)
- **Stories bloquées :** V14-007 (6 moteurs ERP — ModuleForm utilise ScalarioForm)

---

## Definition of Done

- [ ] ScalarioForm widget + state
- [ ] FormConfig Zod + Dart
- [ ] Test E2E commande 6 fields
- [ ] Docs `docs/scalario-form.md`
- [ ] sprint-status.yaml V14-023 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| ScalarioForm widget + state Riverpod | 2.5 |
| Field types (text/number/scan/search/computed/date/select) | 2.0 |
| Integration AlgoEngine (formula live) | 1.0 |
| Integration Sense (capability) + Vault (datasource) | 1.5 |
| ABAC visible_if/readonly_if + validation live | 0.5 |
| Tests E2E commande complète | 0.5 |
| **Total** | **8** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
