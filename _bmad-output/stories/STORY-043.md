# STORY-043 : Validation E2E Gate 0 — Blandine LIVE sur `retail_fresh_produce.json`

**Epic :** EPIC-007 — Premier Template `retail_fresh_produce.json` (Gate 0 Blandine)
**Priorité :** Must Have (story de gating Gate 0)
**Story Points :** 3
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 4 (2026-06-23 → 2026-07-04)
**Dependencies :** STORY-039 (squelette), STORY-040 (modules), STORY-041 (workflow), STORY-042 (i18n + Payment), STORY-026 (BDUIEngine renderer), STORY-037 (sync offline mobile)

---

## User Story

> **En tant que** Carlos, fondateur de Scalario,
> **je veux** **valider end-to-end** que l'architecture BDUI fonctionne avec le template `retail_fresh_produce.json` sur Android — Blandine login → dashboard → POS vente Mobile Money → déclaration perte → clôture caisse → notif soir, **sans une ligne de Flutter métier**, **offline-safe**, **sur 3 rôles** —,
> **so that** Gate 0 (8 juillet 2026) est **passé** : Blandine utilise l'app au quotidien sans aide, et **so that** le template peut servir un 2ème client du même secteur (épicerie fine UEMOA) **sans modifier une ligne de JSON**.

---

## Description

### Background

Cette story est le **gating de Gate 0**. C'est ici qu'on valide que tout l'EPIC-007 (et indirectement EPIC-001 à 006) tient ensemble :
- Le DS rend correctement (STORY-001 à 012).
- Le BDUIEngine charge un template et le rend par rôle (STORY-005 à 007, 026).
- Le ModuleEngine + WorkflowEngine + SecurityChain enforced les permissions (STORY-013 à 029).
- Le sync offline mobile tient sur Android (STORY-037).
- Le template `retail_fresh_produce.json` (STORY-039 à 042) est complet, valide, et fonctionnel.

**Si cette story échoue, Gate 0 échoue.** C'est non négociable au 8 juillet 2026.

**Critère de succès narratif :** un samedi matin de juillet, Aïcha, Issouf et Ibrahim utilisent l'app Scalario pendant **toute une journée** (8h-19h) sur leur téléphone Android. Aïcha fait 30 ventes, déclare 2 pertes, fait sa clôture caisse à 19h. Ibrahim valide un arrivage de 12 cartons mangues + valide les 2 pertes + valide la clôture d'Aïcha. Blandine reçoit la notif soir avec le résumé. **Aucun bug bloquant.** Carlos ne touche pas son téléphone de la journée.

### Scope

**In scope :**

**1. Validation "0 Flutter métier"**

- Audit de code review : `apps/flutter/lib/features/` ne contient aucun `if (role == 'OWNER')` ni aucune logique sectorielle (`if (cause == 'peremption')`...).
- Lint script `scripts/audit-no-business-logic-in-flutter.ts` : grep patterns interdits (rôles en string, `module_id` en string, `sector` en string) dans `lib/features/` et `lib/screens/`. Whitelist : `lib/core/`, `lib/bdui/` (le moteur peut référencer ces noms — c'est son job).
- Code review checklist Carlos signe.

**2. Test E2E "4 fonctions Gate 0"** (sur Android device réel ou émulateur API 34+)

- **Fonction 1 — Dashboard proprio** : Blandine login OWNER → voit dashboard avec 4 KPIs + chart 7j + liste clôtures à valider.
- **Fonction 2 — Validation arrivage** : Ibrahim login MANAGER → tap arrivage en attente → form validation → photo + quantités → validate → state `validé`.
- **Fonction 3 — Déclaration perte** : Aïcha login COMMERCIAL → form perte (article + qté + cause + photo + emplacement) → submit → état `draft` puis Ibrahim valide → état `validated`.
- **Fonction 4 — Clôture caisse** : Aïcha 19h → workflow_cloture_caisse complet (5 steps) → écart 350 FCFA → Ibrahim valide → state `cloture_confirmee`.

**3. Test offline (mode avion)**

- Test scripté Flutter integration (`integration_test/gate0_offline_test.dart`) :
  1. Login en ligne, charge le template, rend dashboard.
  2. Active mode avion (`network_state_emulator` ou stub HTTP).
  3. Effectue 10 actions offline : 5 ventes + 2 pertes + 1 fin de journée + 2 lectures dashboard.
  4. Désactive mode avion.
  5. Vérifie : sync queue Drift vidée, server-side state cohérent (10 actions persistées dans le bon ordre, audit log complet, 0 conflit non résolu).

**4. Test multi-rôle (3 users sur 1 tenant)**

- Test E2E `gate0_multirole_e2e.spec.ts` :
  1. Tenant `blandine_test` provisionné avec 3 users (1 OWNER, 1 MANAGER, 1 COMMERCIAL).
  2. Chaque user login simultanément (3 sessions JWT différentes).
  3. Chaque user fait `GET /layout/dashboard` → reçoit son dashboard rôle-spécifique.
  4. Cross-RBAC : OWNER tente `POST /module_ventes/action {type: create_vente}` → 200 OK. MANAGER tente même → 403 (pas de permission write sur ventes). COMMERCIAL tente `validate_step` clôture → 403.

**5. UAT Blandine** (session humaine)

- Préparation : Carlos prépare un device Android avec l'app installée + tenant `blandine_real` seed avec ses 80 produits réels (importés CSV).
- Session 90 min sur place (boutique Blandine) :
  - 5 min : présentation du flow (sans démontrer).
  - 60 min : Blandine + Aïcha + Ibrahim utilisent l'app sur 4 cas réels (1 arrivage, 5 ventes, 1 perte, 1 clôture).
  - 25 min : feedback structuré (questionnaire SUS ou équivalent simplifié).
- Critère succès : **0 bug bloquant** (un bug bloquant = un user ne peut pas finir une des 4 fonctions Gate 0). Bugs cosmétiques OK, listés dans backlog post-Gate 0.

**6. Validation "sector-first" (template portable)**

- Checklist signée Carlos : un 2ème épicier (`tenant_test_epicier_2`) provisionné avec le **même** `retail_fresh_produce.json`, ses propres 60 produits, ses propres 3 users. **0 modification du JSON.** L'app marche.
- Test rapide manuel : login OWNER tenant 2 → voit son dashboard avec ses propres données. Login COMMERCIAL → POS marche.

**Out of scope :**
- Performance/charge testing (Phase 2 — `k6` ou équivalent).
- Audit sécurité externe (Phase 2 — pen test).
- Onboarding intégrateur certifié (M3 — Gate 1).
- Notification soir push réelle (FCM/APN) — la notif est simulée Phase 1 (entry dans `notifications` table + UI bell). Push réel = Phase 2.
- Compliance OHADA — Phase 3.
- Templates additionnels (pharmacie, BTP) — Phase 2+.

### User Flow (UAT Blandine)

**Samedi 4 juillet 2026 — boutique Blandine, Ouagadougou — 9h00 :**

1. Carlos arrive avec 3 téléphones Android préinstallés (1 par user). Tenant `blandine_real` déjà provisionné.
2. Blandine login OWNER → dashboard. Carlos n'aide pas.
3. Ibrahim login MANAGER. Voit "1 arrivage en attente : 12 cartons mangues fournisseur Sankara".
4. Aïcha login COMMERCIAL → CTA "Vendre" géant. Tape un produit, qty 2, paiement Mobile Money Wave (stub Phase 1 — tap "OK" simule). Vente enregistrée.
5. 10h30 — Ibrahim valide l'arrivage : photo, quantités réelles (12/12), valide. Stock mis à jour.
6. 14h — Aïcha déclare une perte (1 carton péremption tomates). Photo, cause, emplacement "Marché Zogona". Ibrahim valide en 5 min.
7. 18h45 — Aïcha lance clôture caisse. Théorique = 47 500 FCFA, déclaré = 47 200 FCFA. Écart -300 FCFA.
8. 18h47 — Ibrahim reçoit notif (UI badge). Voit clôture en attente. Valide.
9. 19h00 — Blandine voit notif soir : "CA jour 47 500 FCFA, 23 ventes, 1 perte, clôture validée".
10. Feedback Blandine : "C'est plus simple que ce que je pensais. Aïcha n'a pas eu besoin que je lui explique."

**Critère réussite humaine :** 0 fois Carlos a dû intervenir pour débloquer.

---

## Acceptance Criteria

### Audit code "0 Flutter métier"

- [ ] AC-01 — Script `scripts/audit-no-business-logic-in-flutter.ts` exécute :
  - Cherche dans `apps/flutter/lib/features/` et `lib/screens/` les patterns : `'OWNER'`, `'MANAGER'`, `'COMMERCIAL'` (string literals), `'module_'`, `'fresh_produce'`, `'cloture'`, `'arrivage'`, `'perte'`.
  - Whitelist : `lib/core/`, `lib/bdui/`, `*.g.dart`, fichiers explicitement annotés `// bdui-engine: <reason>`.
  - Match hors whitelist → exit code != 0.
- [ ] AC-02 — CI bloque toute PR qui ferait apparaître un de ces patterns hors whitelist.
- [ ] AC-03 — Code review checklist signée par Carlos : "J'ai vérifié manuellement que `lib/features/` ne contient aucune logique métier retail / fresh produce."

### Test E2E "4 fonctions Gate 0"

- [ ] AC-04 — Test E2E `integration_test/gate0_4functions_test.dart` couvre :
  - **F1 Dashboard proprio** : login OWNER → dashboard chargé < 2s → 4 KPIs visibles + chart 7j + au moins 1 entrée dans liste clôtures.
  - **F2 Validation arrivage** : login MANAGER → tap arrivage en attente → form ouvre → champs photo + qté → submit → state passe à `validé` (vérifié via `GET /entities/:id`).
  - **F3 Déclaration perte** : login COMMERCIAL → form perte → submit → entity créée avec `status: draft` → MANAGER valide → `status: validated`.
  - **F4 Clôture caisse** : workflow complet COMMERCIAL submit → écart > 0 → MANAGER validate → state `cloture_confirmee` (cf STORY-041 mais ré-exécuté E2E).
- [ ] AC-05 — Toutes les 4 fonctions tournent **sur Android API 34** (émulateur ou device réel) — pas seulement Flutter Web.
- [ ] AC-06 — Performance : chaque écran charge en < 2s sur device milieu de gamme (Pixel 6 ou équivalent ARM64).

### Test offline

- [ ] AC-07 — Test `integration_test/gate0_offline_test.dart` :
  1. Init online + login.
  2. `network_emulator.disable()` (mock HTTP qui throw).
  3. Effectue 10 actions : 5 ventes (qty/prix variés) + 2 pertes + 1 lecture dashboard + 2 navigations.
  4. Vérifie Drift `sync_queue.length == 8` (les 2 lectures dashboard ne sont pas en queue car cache hit).
  5. `network_emulator.enable()`.
  6. Attends sync via `BullMQ` worker mock.
  7. Vérifie : `sync_queue.length == 0`, server-side `audit_logs.count == 8 + setup` (tous les events tracés), 0 conflit non-résolu.
- [ ] AC-08 — Sync ordre garanti : les 5 ventes sont rejouées dans l'ordre de création (`created_at_local`), pas d'inversion.
- [ ] AC-09 — Idempotence : si on rejoue le test depuis l'étape 6, les 8 mutations ne sont pas dupliquées (vérification par `client_mutation_id`).

### Test multi-rôle

- [ ] AC-10 — Test E2E `services/nestjs/test/e2e/gate0_multirole.e2e-spec.ts` :
  - Provisionne tenant `blandine_test` avec 3 users + 80 produits seed.
  - 3 sessions JWT distinctes.
  - 3 × `GET /layout/dashboard` → 3 ScreenConfigs distincts (assertions sur `screen` field).
  - 3 × `GET /modules/list` → chacun voit ses `nav_modules` selon son rôle.
- [ ] AC-11 — Test cross-RBAC :
  - OWNER `POST /module_ventes/action {create_vente}` → 200.
  - MANAGER même → 403 (`ERR_FORBIDDEN`).
  - COMMERCIAL `POST /module_cloture_caisse/action {validate_step}` → 403.
  - COMMERCIAL `GET /module_ventes/data?scope=all` → 403 (scope `.own` enforced).
- [ ] AC-12 — Test concurrent : 2 users (OWNER et COMMERCIAL) modifient simultanément → server `server_wins`. Conflict queue Drift contient l'entrée perdue côté COMMERCIAL.

### UAT Blandine (session humaine)

- [ ] AC-13 — Session UAT planifiée et exécutée sur la **plage 1-7 juillet 2026** (avant Gate 0).
- [ ] AC-14 — Pendant la session, **0 bug bloquant** observé sur les 4 fonctions Gate 0. Définition bug bloquant : "un user ne peut pas terminer une fonction sans intervention Carlos".
- [ ] AC-15 — Feedback structuré collecté : questionnaire 10 questions (SUS adapté) sur ergonomie, vitesse, clarté. Score moyen ≥ 70/100 (équivalent SUS "good").
- [ ] AC-16 — Les bugs cosmétiques (UI imperfections, latences > 2s, libellés ambigus) sont listés dans backlog post-Gate 0 avec sévérité.

### Validation "sector-first" (template portable)

- [ ] AC-17 — Tenant secondaire `blandine_test_epicier2` provisionné avec :
  - **Même** fichier `retail_fresh_produce.json` (lu depuis catalogue, pas modifié).
  - 3 users distincts (différents emails, mêmes 3 rôles).
  - 60 produits seedés différents (CSV mock).
  - `tenant.config.locale: "fr-CI"` (variation par rapport à blandine_real qui est en `fr-BF`) — preuve i18n.
- [ ] AC-18 — Test smoke manuel sur tenant_2 :
  - Login OWNER → voit son dashboard avec ses propres KPIs.
  - Login COMMERCIAL → POS marche.
  - Vente créée → entity ne contamine **pas** le tenant blandine_real (RLS test).
- [ ] AC-19 — Checklist "sector-first" signée Carlos : 12 points couverts (datasets, locale, devise, providers, navigation, dashboards, modules, workflows, RBAC, audit, sync, KPIs).

### Documentation et release

- [ ] AC-20 — `docs/gate-0-validation-report.md` rédigé :
  - Résumé UAT (score SUS, bugs trouvés / corrigés).
  - Résumé tests E2E (passing rate).
  - Vidéo screencast 5 min de Blandine utilisant l'app (avec son consentement).
  - Liste des limitations connues acceptées Gate 0 (notif push réelle, audit hebdo, OHADA, etc.).
- [ ] AC-21 — `_bmad-output/bmm-workflow-status.yaml` mis à jour : Gate 0 status `passed` avec date.
- [ ] AC-22 — Annonce interne (Notion / blog) : "Gate 0 validé — Blandine LIVE sur Scalario."

---

## Technical Notes

### Composants concernés

- **Tests E2E :**
  - `apps/flutter/integration_test/gate0_4functions_test.dart`
  - `apps/flutter/integration_test/gate0_offline_test.dart`
  - `services/nestjs/test/e2e/gate0_multirole.e2e-spec.ts`
- **Scripts audit :**
  - `scripts/audit-no-business-logic-in-flutter.ts` (étend `audit-business-values.ts` de STORY-042).
- **Provisionning seed :**
  - `services/nestjs/scripts/seed-blandine-real.ts` (80 produits réels).
  - `services/nestjs/scripts/seed-blandine-test-epicier2.ts` (60 produits différents).
- **Documentation :**
  - `docs/gate-0-validation-report.md`
  - Vidéo `docs/assets/blandine-uat-2026-07.mp4`

### Stack de tests

| Niveau | Outil | Cible |
|---|---|---|
| Unit | `flutter test`, `jest` | Couvert par STORY-001 à 042 |
| Integration | `flutter integration_test`, `supertest` | Cette story (E2E user flows) |
| E2E client (Web) | Reporté Phase 2 | — |
| Performance | Reporté Phase 2 (k6) | — |
| UAT humaine | Session in-person Blandine | AC-13 à AC-16 |

### Critères de pass/fail Gate 0

**Pass Gate 0 ssi TOUS les critères suivants sont vert :**
1. AC-01 à AC-22 verts.
2. UAT Blandine sans bug bloquant (AC-14).
3. SUS score ≥ 70 (AC-15).
4. Tenant secondaire fonctionne sans modif JSON (AC-17 à AC-19).

**Fail Gate 0 si :**
- 1 bug bloquant non résolu pendant UAT.
- Tenant secondaire nécessite modif du `retail_fresh_produce.json`.
- Test offline perd une mutation.
- Audit code détecte de la logique métier dans `lib/features/`.

### Conflits de spec — résolutions

- **PRD §FR-022 mentionne 4 fonctions critiques** : "validation croisée, pertes segmentées, clôture caisse, dashboard proprio". **Résolution dans cette story :** "validation croisée" est embarqué dans le workflow d'arrivage et de clôture caisse (la croisée Manager/Commercial est implicite dans les approvals). On valide donc 4 user-facing functions : Dashboard, Validation Arrivage, Déclaration Perte (segmentée par emplacement), Clôture Caisse. Documenté.
- **Sprint plan AC-02 dit "4 fonctions Gate 0 fonctionnelles sur Android"** ✅ aligné.
- **PRD mentionne "notification soir"** : Phase 1 = notification **interne** (entry table + UI bell), pas push FCM/APN. Push réel reporté Phase 2. AC-20 documente cette limitation acceptée Gate 0.
- **Test "Blandine UAT, 0 bug bloquant"** : la définition stricte de "bloquant" est dans AC-14. Bugs cosmétiques OK. Si désaccord pendant UAT, Carlos a le call final (il est le PM).
- **DS vs PRD** : aucun conflit nouveau ici. Tous résolus en STORY-001 à 042.

### Edge cases

- **Blandine indisponible le jour J** : prévoir une fenêtre 1-7 juillet pour décaler. Si Blandine indispo toute la semaine, fallback : UAT avec un client substitut du même secteur (si Carlos en a un sourcé). Si aucun substitut, **escalade Gate 0** : repousser de 1 sprint maximum.
- **Réseau coupé pendant UAT** : c'est un bonus — le test offline est validé en conditions réelles. Documenter.
- **Bug critique trouvé pendant UAT** : hot-fix sprint extension max 3 jours. Si non corrigeable en 3 jours, Gate 0 fail → analyse retro.
- **Device Android non disponible** : émulateur API 34 sur laptop Carlos = fallback. Mais réel device > émulateur pour UAT.
- **2ème épicier (AC-17) impossible à sourcer Phase 1** : provisionner via seed automatique avec données fictives crédibles (60 produits réalistes UEMOA). C'est suffisant pour valider le test sector-first.

### Sécurité

- Le tenant `blandine_real` contient de **vraies données**. Backup PostgreSQL fait avant UAT (script `scripts/backup-db.sh` du repo).
- Logs UAT scrubés avant publication (pas de noms clients dans `gate-0-validation-report.md`).
- Vidéo screencast → consentement écrit Blandine + Aïcha + Ibrahim avant publication.

---

## Dependencies

**Prérequis (techniques) :**
- STORY-039 (squelette domaine).
- STORY-040 (modules).
- STORY-041 (workflow clôture).
- STORY-042 (i18n + Payment).
- STORY-026 (BDUIEngine renderer Flutter complet).
- STORY-037 (sync offline mobile validé).
- STORY-013, 014, 016, 018 (sécurité backend).

**Stories bloquées par celle-ci :** Aucune — c'est la story de gating Gate 0. Les stories Phase 2 dépendent du **statut** Gate 0, pas du code de cette story.

**Externes :**
- Disponibilité Blandine pour UAT (calendrier 1-7 juillet 2026 — bloquer date).
- 3 devices Android API 34+ (Pixel 6/7 milieu de gamme, ARM64).
- Réseau 4G stable + scénario test mode avion.
- Carlos-time : minimum 1 journée complète pour UAT + 1 journée prep.

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-043-gate0-e2e-validation`.
- [ ] 3 fichiers tests E2E présents et verts en CI :
  - `apps/flutter/integration_test/gate0_4functions_test.dart`.
  - `apps/flutter/integration_test/gate0_offline_test.dart`.
  - `services/nestjs/test/e2e/gate0_multirole.e2e-spec.ts`.
- [ ] Script `scripts/audit-no-business-logic-in-flutter.ts` exécutable + intégré CI.
- [ ] Script seed `seed-blandine-real.ts` + `seed-blandine-test-epicier2.ts` fonctionnels.
- [ ] UAT Blandine exécutée et documentée dans `docs/gate-0-validation-report.md`.
- [ ] SUS score ≥ 70 atteint et reporté.
- [ ] Tenant secondaire validé (`blandine_test_epicier2`) sans modification du JSON catalogue.
- [ ] Vidéo screencast 5 min capturée (consentement signé).
- [ ] `_bmad-output/bmm-workflow-status.yaml` : `gate_0_passed: true` + date.
- [ ] Annonce interne (Notion + blog) publiée.
- [ ] Code review : `/codex review` + auto-review Carlos.
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour : STORY-043 status `completed`, sprint 4 `completed_points += 3`.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Test E2E `gate0_4functions_test.dart` (4 fonctions × ~30 assertions) | 0.75 | Le plus volumineux côté Flutter. Setup auth + state cleanup entre tests. |
| Test E2E `gate0_offline_test.dart` (mode avion + 8 mutations + sync verify) | 0.5 | Mock réseau Flutter + assertions sync queue. |
| Test E2E `gate0_multirole.e2e-spec.ts` (3 sessions JWT + cross-RBAC + concurrent) | 0.5 | NestJS supertest standard. |
| Script `audit-no-business-logic-in-flutter.ts` + intégration CI | 0.25 | Étend STORY-042 pattern. |
| Seed scripts `seed-blandine-real.ts` + `seed-blandine-test-epicier2.ts` | 0.25 | CSV import + dataset crédible épicerie. |
| UAT in-person Blandine + capture vidéo + rédaction report | 0.5 | 1 journée prep + 1 journée terrain + 0.5 journée writeup. |
| Validation tenant secondaire (provisioning + smoke test) | 0.25 | Test "sector-first" — 1h. |
| **Total** | **3** | Fibonacci 3 — moderate, mais haute densité d'assertions et un déplacement physique. |

**Rationale :** Cette story est **modeste en volume de code** (les 3 tests E2E sont ~800 LOC ensemble) mais **dense en validation** : 22 ACs, UAT humaine, captures vidéo, rapport. La vraie valeur n'est pas dans le code, c'est dans la **preuve** que tout l'edifice tient. Un Gate 0 sans cette validation E2E = on n'a aucune garantie qu'on ne sera pas en train de débugger en prod chez Blandine.

---

## Notes additionnelles

- **Cette story ne valide pas Gate 1 ni Gate 2** — celles-là sont pour M3 et M9. Gate 1 = 2ème client signé. Gate 2 = 1er intégrateur certifié. Pas dans le scope ici.
- **Lien Blandine ↔ AC :** **chaque** AC trace à un moment Blandine (les 8 phases workflow). AC-04 F1=phase 6 owner KPI, F2=phase 2 manager validation, F3=phase 4 commercial perte, F4=phase 7 commercial+manager clôture. Phase 1 (BC fournisseur création) couvert par STORY-040 module_stock arrivages_form. Phase 5 (seuils alerte) couvert par module_stock alertes_stock_list.
- **Pas de notification push réelle Phase 1** — c'est documenté en limitation acceptée. Push FCM/APN = Phase 2.
- **Audit hebdo (phase 8 Blandine)** non couvert Gate 0. Phase 2.
- **PRD ↔ DS conflict :** aucun nouveau dans cette story.
- **Logo Scalario :** non concerné.
- **Tone direct :** si l'UAT échoue, Gate 0 échoue. Pas de "presque passé" — soit Blandine peut, soit elle ne peut pas. C'est binaire et c'est sain.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
