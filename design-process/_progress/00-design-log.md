# Design Log — Scalario

**Projet :** Scalario
**Méthode :** Whiteport Design Studio (WDS)
**Démarré :** 2026-03-31

---

## Key Decisions

| Date | Décision | Phase | Par |
|------|----------|-------|-----|
| 2026-03-31 | Vision élargie : Scalario = plateforme universelle (pas seulement ERP retail), beachhead UEMOA | Phase 1 | Carlos + Saga |
| 2026-03-31 | Tone of voice : "Pro, Simple, Efficace" — pas de jargon tech | Phase 1 | Carlos + Saga |
| 2026-03-31 | Investisseur gardé en hypothèse (A) — pas TBD, pas développé | Phase 1 | Carlos |
| 2026-03-31 | 4 groupes cibles retenus (dont Ibrahim l'Intégrateur H2) | Phase 2 | Carlos |
| 2026-03-31 | Taux de Frotte = instance du pattern universel "perte naturelle configurable" | Phase 2 | Saga |
| 2026-03-31 | Plateforme multi-plateforme confirmée : mobile + tablette + desktop (Flutter) · Web H2–H3 stack séparée | Phase 3 | Carlos |
| 2026-03-31 | Taux de Frotte réassigné de scénario 09 (Config) à scénario 10 (Stock) — logique module | Phase 3 | Carlos |
| 2026-03-31 | AI Config : accès restreint par rôle + guardrails confirmation obligatoires (clients ne cassent pas la config) | Phase 3 | Carlos |
| 2026-03-31 | GenUI analytics : Blandine pose des questions en langage naturel → listes, graphiques, tableaux générés à la demande | Phase 3 | Carlos |
| 2026-03-31 | Blandine est à l'étranger (hors Burkina Faso) — remote monitoring = seul accès à sa boutique, pas une commodité | Phase 3 | Carlos |
| 2026-03-31 | Employé vend sur desktop (PC boutique) · mobile en fallback si pas de PC disponible | Phase 3 | Carlos |

---

## Progress

### 2026-03-31 — Phase 1 : Product Brief Complet

**Agent :** Saga (Strategic Business Analyst)
**Durée :** Session unique — matériaux existants analysés, 2 gaps comblés
**Qualité :** Excellent

**Artefacts créés :**
- `A-Product-Brief/project-brief.md` — Product Brief complet en français

**Résumé :** Product Brief généré depuis 4 documents existants (Innovation Strategy, Design Thinking, Problem-Solution, PRD v8.3). Gaps comblés : Tone of Voice "Pro, Simple, Efficace" et hypothèse Investisseur maintenue. Vision élargie à plateforme universelle validée.

**Suivant :** Phase 2 — Trigger Mapping

---

### 2026-03-31 — Phase 2 : Trigger Mapping Complet

**Agent :** Saga (Strategic Business Analyst) · Mode Dream
**Scénarios :** 4 personas · 9 objectifs · 5 insights stratégiques
**Qualité :** 10/10

**Artefacts créés :**
- `B-Trigger-Map/00-trigger-map.md` — Hub principal + diagramme Mermaid
- `B-Trigger-Map/01-Business-Goals.md` — Objectifs 3×3 (O1 Revenu · O2 Rétention · O3 Distribution)
- `B-Trigger-Map/02-Blandine-Boutiquiere.md` — Persona P1 Premium · 5 forces positives + 4 négatives
- `B-Trigger-Map/03-Bernard-Boutiquier.md` — Persona P2 Standard · 3 forces positives + 3 négatives
- `B-Trigger-Map/04-Cheick-Chimiste.md` — Persona P3 Standard+ · 3 forces positives + 3 négatives
- `B-Trigger-Map/05-Ibrahim-Integrateur.md` — Persona P4 Partenaire H2 · 3 forces positives + 3 négatives
- `B-Trigger-Map/06-Key-Insights.md` — 5 insights stratégiques + table priorités design P1→P7

**Résumé :** Trigger Map généré en Dream Mode. Insight clé : "Scalario ne vend pas un outil de gestion — il vend la preuve (Blandine), la certitude (Bernard), l'unification (Cheick), la crédibilité récurrente (Ibrahim)." Attribution fear universelle identifiée comme fondation Core non-négociable.

**Suivant :** Phase 3 — UX Scenarios

---

### 2026-03-31 — Phase 3 : UX Scenarios Complet

**Agent :** Saga (UX Scenario Facilitator)
**Scénarios :** 11 scénarios · 33 vues couvertes · couverture 33/33 ✅
**Qualité :** Excellent (10× 7/7·7/7·7/7·4/4 · 1× 7/7·7/7·7/7·3/4)

**Artefacts créés :**
- `C-UX-Scenarios/00-ux-scenarios.md` — Index scénarios + matrice couverture
- `C-UX-Scenarios/01-blandine-ferme-sa-caisse/01-blandine-ferme-sa-caisse.md`
- `C-UX-Scenarios/01-blandine-ferme-sa-caisse/01.1-arret-caisse-etape-1/01.1-arret-caisse-etape-1.md`
- `C-UX-Scenarios/02-blandine-surveille-a-distance/02-blandine-surveille-a-distance.md`
- `C-UX-Scenarios/02-blandine-surveille-a-distance/02.1-dashboard-proprietaire/02.1-dashboard-proprietaire.md`
- `C-UX-Scenarios/03-bernard-decouvre-scalario-seul/03-bernard-decouvre-scalario-seul.md`
- `C-UX-Scenarios/03-bernard-decouvre-scalario-seul/03.1-splash/03.1-splash.md`
- `C-UX-Scenarios/04-bernard-vend-et-sait-ce-quil-a-gagne/04-bernard-vend-et-sait-ce-quil-a-gagne.md`
- `C-UX-Scenarios/04-bernard-vend-et-sait-ce-quil-a-gagne/04.1-dashboard-employe/04.1-dashboard-employe.md`
- `C-UX-Scenarios/05-cheick-configure-ses-variantes/05-cheick-configure-ses-variantes.md`
- `C-UX-Scenarios/05-cheick-configure-ses-variantes/05.1-produits-liste-catalogue/05.1-produits-liste-catalogue.md`
- `C-UX-Scenarios/06-cheick-vend-a-un-client-a-credit/06-cheick-vend-a-un-client-a-credit.md`
- `C-UX-Scenarios/06-cheick-vend-a-un-client-a-credit/06.1-clients-liste/06.1-clients-liste.md`
- `C-UX-Scenarios/07-cheick-agit-sur-ses-peremptions/07-cheick-agit-sur-ses-peremptions.md`
- `C-UX-Scenarios/07-cheick-agit-sur-ses-peremptions/07.1-peremptions-tableau-de-bord/07.1-peremptions-tableau-de-bord.md`
- `C-UX-Scenarios/08-ibrahim-deploie-son-premier-client/08-ibrahim-deploie-son-premier-client.md`
- `C-UX-Scenarios/08-ibrahim-deploie-son-premier-client/08.1-ai-config-wizard/08.1-ai-config-wizard.md`
- `C-UX-Scenarios/09-configuration-de-la-boutique/09-configuration-de-la-boutique.md`
- `C-UX-Scenarios/09-configuration-de-la-boutique/09.1-utilisateurs-liste-roles/09.1-utilisateurs-liste-roles.md`
- `C-UX-Scenarios/10-le-gestionnaire-receptionne-une-livraison/10-le-gestionnaire-receptionne-une-livraison.md`
- `C-UX-Scenarios/10-le-gestionnaire-receptionne-une-livraison/10.1-stock-reception-marchandise/10.1-stock-reception-marchandise.md`
- `C-UX-Scenarios/11-blandine-lit-ses-rapports/11-blandine-lit-ses-rapports.md`
- `C-UX-Scenarios/11-blandine-lit-ses-rapports/11.1-rapports-ventes/11.1-rapports-ventes.md`

**Résumé :** 11 scénarios couvrant 33 vues sans doublon. Décisions clés : Taux de Frotte réassigné au module stock (scénario 10), AI Config avec guardrails rôle (scénario 09), GenUI analytics pour Blandine (scénario 11), contexte Blandine à l'étranger intégré dans tous ses scénarios. Employé vend sur desktop, Bernard consulte depuis mobile ou desktop selon disponibilité.

**Suivant :** Phase 4 — UX Design

---

---

### 2026-04-01 — Phase 4 : UX Design Complet (33 pages)

**Mode :** [S] Suggest scénarios 01–04 · [D] Dream scénarios 05–11
**Pages :** 33 pages · 11 scénarios · 8 HTML prototypes + specs par session
**Qualité :** Validé (S) ou auto-généré (D) · logo Sc corrigé en cours de session

**Artefacts créés :**

- 33 prototypes HTML (`*/prototypes/*.html`) + 33 specs (`*-p4-spec.md`)
- 11 `scenario-tracking.yaml` (01→11)
- Décisions clés : PIN identification additive (pas redondante), sidebar desktop + bottom nav mobile, Taux de Frotte → scénario 10, GenUI → scénario 11 (Premium differentiator)

**Suivant :** Phase 5 — Agentic Development

---

### 2026-04-01 — Phase 5 : [A] Analysis — Architecture Flutter

**Scope :** Codebase Flutter entier (`apps/frontend/lib/`)
**Output :** `G-Product-Development/flutter-architecture-analysis.md`

**Findings clés :**
- Architecture : Clean Architecture feature-first · Riverpod · Isar · Supabase · SDUI dashboard
- Navigation : NavigationRail (≥600dp) / BottomNav (<600dp) · module-gated · role-driven (BusinessTypeConfig)
- Rôles : superadmin · owner · manager · commercial · cashier
- SDUI enregistré : product_grid · cart_panel · kpi_card_grid · line_chart · terminal_status_list

**Gap analysis (33 pages UX) :**
- ✅ Existe : 14 pages (POS complet, dashboard SDUI, freshness, stock, contacts, splash/login)
- ⚠️ Partiel : 12 pages (fermeture caisse éparpillée, alertes non unifiées, rapports sans GenUI)
- ❌ Manque : 7 items (PIN employé 04.1, onboarding 03.3, team management 09.1/09.2, intégrations 09.4, AI Config 08.1, GenUI 11.x)

**Priorités :**
1. Démo Blandine (avant mi-avril) : PIN 04.1 · flow caisse 01.x · alertes unifiées 02.2
2. Post-démo H1 : gestion équipe (09.x) · Taux de Frotte complet (10.1)
3. H2 : GenUI Analytics · onboarding wizard · Ibrahim panel

**Suivant :** Phase 5 [D] Development ou [E] Evolution — implémenter par priorité

---

_Design Log Scalario · WDS · 2026-03-31_
