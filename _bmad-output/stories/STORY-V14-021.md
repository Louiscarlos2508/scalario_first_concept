# STORY-V14-021 : Business Profile Document — UI formulaire libre + sauvegarde auto + extraction IA

**Epic :** EPIC-V14-012 — Scalario Forge
**Priorité :** Must Have
**Story Points :** 5
**Status :** defined
**Sprint :** v14-9 (Phase 2)
**Dépendances :** V14-019 (Config Agent qui consomme le profile)

---

## User Story

> **En tant que** futur client Scalario,
> **je veux** remplir un **Business Profile** structuré (5 sections : activité, équipes, processus, outils, spécificités) à mon rythme avec sauvegarde auto, et que l'IA en extraie automatiquement la config technique de mon ERP,
> **so that** au lieu d'une conversation chat longue qui me fait procrastiner, je remplis un formulaire structuré en 30 min, je le valide, et l'IA prend le relais.

---

## Description

### Background

PRD v14 §17 — le Business Profile remplace les longues conversations chat (procrastination). Format guidé :

```
1. VOTRE ACTIVITÉ : nom, secteur, ville, taille (1-10 / 11-50 / 50+), description libre
2. VOS ÉQUIPES : types d'employés et leurs rôles (texte libre)
3. VOS PROCESSUS : workflow vente typique, validations/approbations
4. VOS OUTILS ACTUELS : Excel/Cahier/Logiciel autre
5. SPÉCIFICITÉS : offline ? mobile ? règles métier importantes
```

L'IA extrait automatiquement : secteur, rôles, workflow, ABAC rules, capabilities, offline-critical, devices, modules.

### Scope

**In scope :**
- Flutter Web screen `lib/features/onboarding/business_profile_form.dart`
- Sauvegarde auto chaque 30s (`PATCH /api/v1/tenants/:slug/business_profile`)
- Bouton "Soumettre" → trigger Scalario Forge extraction
- Display résumé technique généré par l'IA (V14-019)
- Display 3-7 questions de précision (V14-019)
- Validation finale → Demo Space (V14-020)
- 5 sections du formulaire avec validation client-side

**Out of scope :**
- L'extraction IA elle-même — V14-019 (Scalario Forge backend)
- Demo Space — V14-020
- Multi-langue formulaire — Phase 3

---

## Acceptance Criteria

- [ ] **AC-01** — Formulaire Flutter Web avec 5 sections (Activité, Équipes, Processus, Outils, Spécificités).
- [ ] **AC-02** — Sauvegarde auto toutes les 30s (`PATCH /tenants/:slug/business_profile`).
- [ ] **AC-03** — Indicateur visuel sauvegarde ("Sauvegarde il y a 15s").
- [ ] **AC-04** — User peut quitter et revenir → données préservées.
- [ ] **AC-05** — Validation client-side : sections obligatoires (1, 2, 3), sections optionnelles (4, 5).
- [ ] **AC-06** — Bouton "Soumettre pour analyse" actif si sections obligatoires OK.
- [ ] **AC-07** — Submit → POST `/api/v1/tenants/:slug/business_profile/analyze` → Scalario Forge tourne en background.
- [ ] **AC-08** — Polling/SSE : quand analyse prête (2-3 min), affiche résumé technique en français.
- [ ] **AC-09** — Affiche 3-7 questions de précision (choix multiples) générées par Forge.
- [ ] **AC-10** — User répond → POST `/api/v1/tenants/:slug/business_profile/clarify { answers }` → Forge re-run.
- [ ] **AC-11** — Si confiance ≥ 80% après questions → bouton "Lancer le Demo Space".
- [ ] **AC-12** — Test E2E : remplir profile pharma → submit → résumé + questions → answers → demo space init.

---

## Technical Notes

### Schema Business Profile (Pydantic + Zod NestJS)

```typescript
interface BusinessProfile {
  activite: {
    nom: string;
    secteur: string;  // texte libre (Forge classera)
    ville: string;
    taille: '1-10' | '11-50' | '50+';
    description: string;
  };
  equipes: { description: string };  // ex: "Vendeurs (3) prennent les commandes et gèrent le stock"
  processus: {
    vente_typique: string;
    validations: string;
  };
  outils: {
    excel: boolean;
    cahier: boolean;
    logiciel: boolean;
    logiciel_nom?: string;
  };
  specificites: {
    offline: boolean;
    mobile_devices: string;  // ex: "tablettes Android"
    regles_metier: string;
  };
  is_complete: boolean;
}
```

### Edge cases

- Profile vide → ne pas envoyer à Forge (erreur "Remplir au moins l'activité + équipes")
- Réseau coupe pendant la sauvegarde → queue locale, retry
- Forge timeout (> 5 min) → message "Désolé, l'analyse prend plus longtemps que prévu, réessaye"

---

## Dependencies

- **Prérequis :** V14-019 (Forge)
- **Stories bloquées :** V14-020 (Demo Space — point d'entrée depuis ici)

---

## Definition of Done

- [ ] UI formulaire 5 sections + sauvegarde auto
- [ ] Soumission → résumé technique + questions
- [ ] Test E2E remplir → demo space
- [ ] sprint-status.yaml V14-021 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| UI Flutter Web 5 sections | 1.5 |
| Sauvegarde auto + indicateur | 0.5 |
| Submit + polling SSE résumé | 1.0 |
| Display résumé + questions clarification | 1.0 |
| Tests E2E | 1.0 |
| **Total** | **5** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
