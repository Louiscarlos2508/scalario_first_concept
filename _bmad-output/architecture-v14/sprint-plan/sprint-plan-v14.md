# Sprint Plan Scalario v14 — Phase 1 (Mois 1-3)

**Période** : 2026-05-25 → 2026-08-25 (3 mois)
**Vélocité observée Sprint 1-4 v13** : 36-44 pts / sprint (avg 40)
**Capacité v14 Phase 1** : 6 sprints × 2 semaines × 42 pts = **252 pts**
**Total points stories Phase 1** : ~50 pts (V14-001 à V14-013)
**Marge** : énorme — on garde l'effort pour le refactor Sprint 1-4 et la stabilisation.

---

## Vue d'ensemble Phase 1

L'objectif Phase 1 v14 = **livrer manuellement les premiers ERP à des vrais clients**, en s'appuyant sur :
- Le code Sprint 1-4 v13 (renommé/réorganisé)
- Les nouveaux engines de fondation (Variantes, Widgetbook, Scalario Calc, Scalario Live, i18n complet, Swagger)
- Pas encore de Scalario Forge IA (Phase 2)
- Pas encore de Scalario Stage (Phase 2)
- Pas encore de FastAPI microservice IA (Phase 2)
- Pas encore de CRDT (reste Phase 2 — server_wins Phase 1 OK)

---

## Sprint v14-1 (Mai 26 - Juin 8) — Migration nomenclature + Refactor catalogue

**Goal** : aligner le code existant Sprint 1-4 avec la nomenclature v14.

| Story | Pts | Bloc |
|---|---|---|
| V14-001 | Script migration nomenclature Scalario | 2 |
| V14-005 | Restructure NestJS (core/engines/bdui/config-agent/modules/ai) | 3 |
| V14-006 | Catalogue v14 (modules génériques + ux_profiles + queries) | 5 |
| V14-002 | JSON Schema BDUI + champ `variant` | 3 |

**Total** : 13 pts (volontairement léger, c'est du refactor sensible).

**Livrables sprint** :
- Code Sprint 1-4 renommé : `BDUIEngine → ScalarioCanvas`, `ModuleEngine → ScalarioFlow`, etc.
- Nouvelle structure NestJS `src/core/ + engines/ + bdui/ + ...`
- Catalogue restructuré (`catalog/modules/gestion/...`, `catalog/ux_profiles/...`, `catalog/queries/...`)
- ComponentConfig JSON accepte `variant` + `actions` + `children`
- Tous les tests existants verts après migration

---

## Sprint v14-2 (Juin 9 - Juin 22) — Variantes + Widgetbook

**Goal** : système de variantes opérationnel, catalogue composants visible dans Widgetbook.

| Story | Pts | Bloc |
|---|---|---|
| V14-003 | ComponentRegistry dispatch par variante | 5 |
| V14-004 | Catalogue composants × variantes (12 composants, ~50 variantes) | 5 |
| V14-010 | Widgetbook setup + tous composants × variantes × états | 5 |

**Total** : 15 pts.

**Livrables sprint** :
- `KPICard.fromConfig(config, ctx)` résout `variant: 'auto'` → KPICardCompact selon contexte
- 12 composants × ~50 variantes visibles dans Widgetbook
- Golden tests Light + Dark pour chaque variante
- Memory `feedback_scalario_variants.md` (1 type + N variantes)

---

## Sprint v14-3 (Juin 23 - Juillet 6) — Scalario Calc + Scalario Live

**Goal** : engine de calcul + realtime serveur→app opérationnels.

| Story | Pts | Bloc |
|---|---|---|
| V14-011 | Scalario Calc — 30 fonctions atomiques + AlgoEngine.eval | 5 |
| V14-012 | Scalario Live — WebSocket Gateway + Flutter listener + FCM/APN enregistrement | 5 |
| V14-008 | i18n complet ARB FR/EN + lint `no_hardcoded_strings` | 5 |

**Total** : 15 pts.

**Livrables sprint** :
- `catalog/algo/primitives/` (math, logique, listes, dates, texte) — 30 fonctions Zod/Dart dual runtime
- `AlgoEngine.eval(formula, inputs)` mode debug avec arbre d'évaluation
- WebSocket Gateway NestJS + 4 events (`validation_required`, `stock_critical`, `config_updated`, `alert_triggered`)
- Flutter `ScalarioLive` listener + integration avec NotificationService
- ARB FR/EN extraits depuis tout le catalog/ — lint actif en CI

---

## Sprint v14-4 (Juillet 7 - Juillet 20) — 6 moteurs ERP génériques

**Goal** : ModuleList/Form/Detail/Report/Kanban/Dashboard opérationnels.

| Story | Pts | Bloc |
|---|---|---|
| V14-007 | 6 moteurs ERP génériques + catalogue Phase 1 | 8 |
| V14-009 | @nestjs/swagger global | 3 |
| V14-013 | tenant_handle + network_public columns (anticipation Phase 4) | 2 |

**Total** : 13 pts.

**Livrables sprint** :
- 6 widgets Flutter `module_*_screen.dart` rendent n'importe quelle entité depuis JSON
- Routing `go_router` `/modules/:moduleId` → résolution dynamique
- Endpoints NestJS génériques `POST /:tenant/:moduleId/action` + `GET /:tenant/:moduleId/data`
- Catalogue démarrage : commandes, stock, factures, employes, conges, livraisons
- Héritage `inherits` + `overrides` deep-merge testé E2E
- Swagger `/api/docs` opérationnel

---

## Sprint v14-4b (Juillet 14 - Juillet 20) — Flow Engine Hardening

**Goal** : boucher les 3 gaps du Flow Engine avant le premier client réel.

| Story | Pts | Bloc |
|---|---|---|
| V14-FLOW-001 | Loop runtime réel (itération collection + variable as) | 5 |
| V14-FLOW-002 | Persistance delays (table PostgreSQL + cron resume) | 3 |
| V14-FLOW-003 | Webhook sortant fonctionnel (fetch + retry + HMAC) | 5 |

**Total** : 13 pts.

**Livrables sprint** :
- `dispatchStep` case `loop` : itération réelle sur collection avec variable `as`
- Table `flow_pending_delays` + cron toutes les 5s pour reprise des delays après crash
- `FlowWebhookService` : fetch HTTP avec retry 3x, HMAC SHA-256, timeout 10s
- Tests : 17+ nouveaux tests (5 loop, 5 delays, 7 webhooks)
- Tous les tests existants flow verts (0 régression)

---

## Sprint v14-5 (Juillet 21 - Août 3) — Premier client réel (Scalario Forge manuel)

**Goal** : configurer le premier client réel **manuellement** (sans IA encore — Scalario Labs opère).

| Activité | Pts |
|---|---|
| Onboarding client 1 — Business Profile rédigé avec lui | 5 |
| Génération manuelle de la config tenant_config (Labs opère via SQL + JSON édité à la main) | 8 |
| Demo "fait main" — Carlos joue les rôles devant le client | 5 |
| Itérations + ajustements (3-5 cycles) | 5 |
| Go Live + import données CSV | 5 |

**Total** : ~28 pts.

**Livrables sprint** :
- 1 tenant client réel opérationnel sur l'infrastructure Scalario Labs
- Documentation onboarding manuel (ce que Scalario Forge automatisera en Phase 2)
- Liste des hallucinations / erreurs / améliorations à corriger en Phase 2
- Premier MRR encaissé

---

## Sprint v14-6 (Août 4 - Août 17) — Stabilisation + Client 2-3

**Goal** : valider que le moteur tient sur 2-3 clients en parallèle, lever les bugs critiques.

| Activité | Pts |
|---|---|
| Client 2 onboarding (autre secteur) | 8 |
| Client 3 onboarding (autre secteur) | 8 |
| Refactor catalogue selon patterns observés | 5 |
| Documentation Phase 2 (ce que Scalario Forge devra faire) | 5 |
| Bugs critiques + monitoring | 5 |

**Total** : ~31 pts.

**Livrables sprint** :
- 3 clients actifs sur Scalario Labs
- ~3 mois MRR confirmé
- Roadmap Phase 2 Scalario Forge précisée

---

## Récap Phase 1 — 7 sprints (3 mois + 1 semaine)

| Sprint | Dates | Goal | Pts |
|---|---|---|---|
| v14-1 | 26 mai → 8 juin | Migration nomenclature + restructure catalogue | 13 |
| v14-2 | 9 juin → 22 juin | Variantes + Widgetbook | 15 |
| v14-3 | 23 juin → 6 juillet | Scalario Calc + Live + i18n | 15 |
| v14-4 | 7 juillet → 13 juillet | 6 moteurs ERP génériques + Swagger | 13 |
| v14-4b | 14 juillet → 20 juillet | **Flow Engine Hardening** (loop + delays + webhook) | 13 |
| v14-5 | 21 juillet → 3 août | **Premier client réel** (manuel) | 28 |
| v14-6 | 4 août → 17 août | Stabilisation + clients 2-3 | 31 |
| **Total** | **~3 mois** | **3 clients réels actifs** | **128 pts** |

---

## Definition of Done — Phase 1 v14

- [ ] Code Sprint 1-4 v13 entièrement renommé en nomenclature v14
- [ ] Variantes opérationnelles dans Widgetbook
- [ ] Scalario Calc + Scalario Live livrés
- [ ] Flow Engine hardened (loop réel, delays persistants, webhook sortant)
- [ ] i18n FR/EN complet, lint `no_hardcoded_strings` actif en CI
- [ ] 6 moteurs ERP génériques rendent n'importe quelle entité depuis JSON
- [ ] Catalogue démarrage : ≥ 8 modules standards committés
- [ ] @nestjs/swagger opérationnel
- [ ] **3 clients réels actifs** sur infrastructure Scalario Labs (configurés manuellement par Carlos)
- [ ] MRR ≥ 3 × abonnement mensuel confirmé
- [ ] Roadmap Phase 2 Scalario Forge précisée

---

## Risques Phase 1

| Risque | Mitigation |
|---|---|
| Migration nomenclature casse des choses subtiles | V14-001 commit par bloc, rollback automatique si tests échouent |
| Variantes système plus complexe que prévu | Limiter Phase 1 à 12 composants × 3-4 variantes moyennes ; auto resolution simple |
| i18n extraction massive bloque le sprint | Faire ARB FR à 100% en Phase 1, EN à 40% (Phase 2 ARB Africaines) |
| 6 moteurs génériques pas assez flexibles | Documenter patterns d'override deep-merge, prévoir module custom Phase 2 |
| Flow Engine loop non testé sur collections réelles | V14-FLOW-001 ajoute 5+ tests couvrant edge cases (vide, inexistant, nested) |
| Trouver le premier client réel | Carlos doit prospecter en parallèle dès sprint v14-1 |
| Hallucinations LLM (mais pas de LLM Phase 1) | Phase 1 = Scalario Labs opère manuellement, pas de risque LLM |
