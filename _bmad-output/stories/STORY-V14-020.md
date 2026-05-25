# STORY-V14-020 : Scalario Stage — Demo Space multi-rôles (3 modes Joueur/Réalisateur/Formation)

**Epic :** EPIC-V14-013 — Scalario Stage (Demo Space)
**Priorité :** Must Have
**Story Points :** 8
**Status :** defined
**Sprint :** v14-9 (Phase 2)
**Dépendances :** V14-019, STORY-009 v13 (Sandbox JSON base)

---

## User Story

> **En tant que** client Scalario qui vient de configurer son ERP avec Scalario Forge,
> **je veux** un espace de test **sandbox** avec données fictives réalistes où je peux voir **tous les rôles simultanément** (mode Réalisateur), ou jouer 1 rôle pendant que l'IA simule les autres (mode Joueur), ou être guidé étape par étape (mode Formation),
> **so that** je teste mon ERP avant le go live, je vois si la config matche mon métier, et j'ajuste en chat IA en temps réel.

---

## Description

### Background

PRD v14 §19 — Scalario Stage = le moment où la magie opère. Le client voit son ERP en action **avant** de l'utiliser en prod. C'est la couche 5 d'anti-hallucination (test réel par le client).

### Scope

**In scope :**
- Sandbox tenant `<real_tenant>_stage` avec données fictives générées par Scalario Forge.
- 3 modes UI :
  - **Joueur** 🎮 : client joue 1 rôle, autres simulés par IA
  - **Réalisateur** 🎬 : tous rôles visibles simultanément (Flutter desktop optimisé, grid 3-4 colonnes)
  - **Formation** 🎓 : tutoriel guidé étape par étape pour former les futurs utilisateurs
- Scénarios guidés IA (ex: "Une commande > 500k arrive → validation DG → facturation auto") rejouable
- Chat IA intégré : "Le seuil de validation devrait être 200k pas 500k" → modification config en temps réel + rejeu scénario
- Données fictives réalistes : 50-100 commandes / 200-500 produits / 5-20 users / dates étalées sur 30j
- Bouton "Go Live" qui transitionne sandbox → production (avec import données réelles Excel/CSV)

**Out of scope :**
- Réelle prod après Go Live — manuel par Scalario Labs Phase 1, automatique Phase 3
- Multi-langue dans Demo Space — utilise locale tenant

---

## Acceptance Criteria

- [ ] **AC-01** — `POST /api/v1/tenants/:slug/stage/init` génère un sandbox tenant avec données fictives.
- [ ] **AC-02** — Mode Joueur : Flutter rend `dashboard_<role>` du rôle sélectionné, IA simule les actions des autres rôles en background.
- [ ] **AC-03** — Mode Réalisateur : Flutter Web/Desktop rend 3-4 colonnes simultanément, 1 par rôle, données partagées en temps réel via WebSocket Scalario Live.
- [ ] **AC-04** — Mode Formation : tutoriel scénarisé (commande → validation → livraison → facturation) avec popups d'explication.
- [ ] **AC-05** — Chat IA intégré dans le Demo Space (sidebar), tout le contexte de la config + scénario joué disponible pour l'IA.
- [ ] **AC-06** — Modification config en chat : "Mets le seuil à 200k" → Scalario Forge modifie `tenant_config`, scénario en cours se rejoue avec la nouvelle règle.
- [ ] **AC-07** — Bouton "Go Live" : (a) snapshot config validée, (b) modal "Importer mes données" (CSV/Excel), (c) bascule sandbox → production.
- [ ] **AC-08** — Rollback 30 jours : si après go live le client veut revenir à une version précédente → 1 clic, restauration depuis `tenant_config_history`.
- [ ] **AC-09** — Tests : 3 sectoriels (pharma, BTP, commerce) — Demo Space init + tour des 3 modes + ajustement chat.

---

## Technical Notes

### Architecture

```
Demo Space orchestration (Phase 2) :
- NestJS controller /tenants/:slug/stage/* (init, switch_mode, go_live, rollback)
- Sandbox tenant = `<slug>_stage` avec un flag `is_sandbox: true`
- Données fictives générées par Scalario Forge agent `data-generator.py` (FastAPI)
- Flutter Web/Desktop : `lib/features/stage/` avec 3 widgets DemoPlayer / DemoDirector / DemoFormation
- Chat IA : reuse Scalario Forge UI (WebSocket SSE streaming)
```

### Données fictives

```python
# data-generator.py
async def generate_fictive_data(erp_config: ERPConfig, n_days: int = 30):
    # Génère 50-100 commandes étalées sur n_days
    # 200-500 produits dans le stock
    # 5-20 utilisateurs avec rôles variés
    # 30 cas edge : grosses commandes, retours, litiges, ruptures stock
    ...
```

### Edge cases

- Client demande "rejouer un scénario d'il y a 10 min" → snapshot + replay déterministe
- Ajustement chat incompatible avec config existante → Forge alerte "Cela invaliderait X — ok ?"
- Go Live échoue (import CSV malformé) → message clair + rollback automatique

---

## Dependencies

- **Prérequis :** V14-019 (Forge génère la config + données fictives), STORY-009 v13 (Sandbox base)
- **Stories bloquées :** V14-022 (anti-hallucination couche 5 = Demo Space)

---

## Definition of Done

- [ ] Init sandbox + 3 modes UI
- [ ] Chat IA intégré + ajustement temps réel
- [ ] Bouton Go Live + Rollback 30j
- [ ] 3 tests sectoriels
- [ ] sprint-status.yaml V14-020 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Sandbox tenant init + data-generator | 1.5 |
| Mode Joueur (Flutter) | 1.5 |
| Mode Réalisateur (Flutter Web 3 colonnes) | 2.0 |
| Mode Formation (tutoriel guidé) | 1.0 |
| Chat IA intégré + ajustement live | 1.5 |
| Go Live + Rollback 30j | 0.5 |
| **Total** | **8** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
