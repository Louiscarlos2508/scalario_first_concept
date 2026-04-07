# UX Scenarios — Scalario Retail Phase 1

> Index des 10 scénarios UX + audit de l'existant + delta à designer

**Document:** UX Scenarios Hub
**Created:** 2026-04-06
**Status:** COMPLETE
**Method:** Whiteport Design Studio (WDS) — Phase 3

---

## Approche

L'app Scalario a été codée sans maquettes (~56 écrans Flutter existants). Cette Phase 3 :

1. **Outline les 10 scénarios UX** ancrés sur les 3 personas (Blandine, Yempabou, Vivien) et le driver #1 "qu'est-ce qui s'est passé pendant que je n'étais pas là".
2. **Audit chaque page** vs le code existant : `garder` / `retoucher` / `refondre` / `créer`.
3. **Outline détaillé uniquement le delta** (les pages à toucher), pas les pages "garder tel quel".
4. **Sert de brief Figma** pour produire les maquettes définitives, qui guideront la ré-implémentation Flutter.

---

## Vue d'ensemble — couverture

- **41 pages cibles** organisées en 10 scénarios
- **56 écrans Flutter existants** dont **38 mappés et validés "garder"**, **15 hors-scope Phase 1**, **1 doublon à supprimer**, **2 à fusionner**
- **14 écrans à toucher (delta)** : 6 créations + 8 refontes UX
- **14 page specs delta détaillés** dans ce dossier

---

## Liste des 10 scénarios

| # | Scénario | Persona | Priorité | Pages | Delta |
|---|---------|---------|----------|-------|-------|
| 01 | [Blandine pilote depuis Dakar](01-blandine-pilote-depuis-dakar/01-blandine-pilote-depuis-dakar.md) | Blandine ⭐ | P1 | 9 | 2 (Centre notif + Rapport pertes) |
| 02 | [Vivien encaisse une vente](02-vivien-encaisse-une-vente/02-vivien-encaisse-une-vente.md) | Vivien | P1 | 3 | 0 |
| 03 | [Blandine valide une commande interne](03-blandine-valide-une-commande-interne/03-blandine-valide-une-commande-interne.md) | Blandine ⭐ | P1 | 3 | 0 |
| 04 | [Yempabou démasque les pertes](04-yempabou-demasque-les-pertes/04-yempabou-demasque-les-pertes.md) | Yempabou | P1 | 3 | 2 |
| 05 | [Yempabou clôture sa caisse](05-yempabou-cloture-sa-caisse/05-yempabou-cloture-sa-caisse.md) | Yempabou | P1 | 3 | 1 |
| 06 | [Blandine pilote son stock frais](06-blandine-pilote-son-stock-frais/06-blandine-pilote-son-stock-frais.md) | Blandine ⭐ | P2 | 5 | 3 |
| 07 | [Yempabou suit ses clients à crédit](07-yempabou-suit-ses-clients-credit/07-yempabou-suit-ses-clients-credit.md) | Yempabou | P2 | 3 | 2 |
| 08 | [Yempabou réceptionne une livraison](08-yempabou-receptionne-livraison/08-yempabou-receptionne-livraison.md) | Yempabou | P2 | 3 | 3 |
| 09 | [Blandine surveille les dépenses](09-blandine-surveille-les-depenses/09-blandine-surveille-les-depenses.md) | Blandine ⭐ | P2 | 2 | 0 |
| 10 | [Yempabou met sa boutique en route](10-yempabou-met-sa-boutique-en-route/10-yempabou-met-sa-boutique-en-route.md) | Tous | P3 | 7 | 1 |
| 11 | [Blandine pilote multi-boutique](11-blandine-pilote-multi-boutique/11-blandine-pilote-multi-boutique.md) | Blandine ⭐ | P1 | 6 | 5 créations + 1 retouche |

**Total pages : 41** — **Delta : 14 page specs détaillés** (6 créations + 8 refontes)

---

## Periheter UX Phase 1 — version finale consolidée

### ❌ À CRÉER (6 pages)

| # | Page | Scénario | Page spec |
|---|---|---|---|
| 2 | Sélection profil utilisateur | 10 | [10.2](10-yempabou-met-sa-boutique-en-route/10.2-selection-profil/10.2-selection-profil.md) |
| 14 | Création/édition produit | 06 | [06.3](06-blandine-pilote-son-stock-frais/06.3-creation-produit/06.3-creation-produit.md) |
| 19 | Résultat inventaire | 04 | [04.3](04-yempabou-demasque-les-pertes/04.3-resultat-inventaire/04.3-resultat-inventaire.md) |
| 26 | Liste fournisseurs | 08 | [08.1](08-yempabou-receptionne-livraison/08.1-liste-fournisseurs/08.1-liste-fournisseurs.md) |
| 27 | Fiche fournisseur | 08 | [08.2](08-yempabou-receptionne-livraison/08.2-fiche-fournisseur/08.2-fiche-fournisseur.md) |
| 38 | Centre notifications | 01 | [01.1](01-blandine-pilote-depuis-dakar/01.1-centre-notifications/01.1-centre-notifications.md) |

### 🔧 À REFONDRE UX (8 pages)

| # | Page | Écran existant | Scénario | Page spec |
|---|---|---|---|---|
| 12 | Liste produits | CategoriesScreen | 06 | [06.1](06-blandine-pilote-son-stock-frais/06.1-liste-produits/06.1-liste-produits.md) |
| 16 | Mouvements stock | StockViewPage | 06 | [06.5](06-blandine-pilote-son-stock-frais/06.5-mouvements-stock/06.5-mouvements-stock.md) |
| 17 | Liste inventaires | InternalRequestsScreen | 04 | [04.1](04-yempabou-demasque-les-pertes/04.1-liste-inventaires/04.1-liste-inventaires.md) |
| 20 | Caisse ouverte | UnifiedSessionsScreen | 05 | [05.1](05-yempabou-cloture-sa-caisse/05.1-caisse-ouverte/05.1-caisse-ouverte.md) |
| 28 | Réception marchandise | PurchaseOrderDetailScreen | 08 | [08.3](08-yempabou-receptionne-livraison/08.3-reception-marchandise/08.3-reception-marchandise.md) |
| 32 | Fiche client | (éclaté dans client_order_detail) | 07 | [07.2](07-yempabou-suit-ses-clients-credit/07.2-fiche-client/07.2-fiche-client.md) |
| 33 | Paiement crédit | (dialog settle_debt) | 07 | [07.3](07-yempabou-suit-ses-clients-credit/07.3-paiement-credit/07.3-paiement-credit.md) |
| 37 | Rapport pertes (vraie analytique) | LossDeclarationPage (déclaration ≠ rapport) | 01 | [01.6](01-blandine-pilote-depuis-dakar/01.6-rapport-pertes/01.6-rapport-pertes.md) |

### 🔧 RETOUCHE MINEURE (1 page)

| # | Page | Action |
|---|---|---|
| 34 | Hub rapports | Masquer la section GenUI mockup (pas d'IA Phase 1) |

### ✅ À GARDER tel quel (32 pages mappées)

Toutes les autres pages des scénarios 01, 02, 03, 04 (18), 05 (21, 22), 06 (13, 15), 07 (31), 09, 10 (sauf 10.2). Voir audit dans chaque scénario.

### 🚫 À DÉSACTIVER (15 écrans hors-scope Phase 1, via feature flags)

Admin (8) : AdminDashboard, AdminBilling, AdminTenants, AdminMonitoring, AdminModules, BusinessTypes, TenantDetail, NewTenantForm
Billing (2) : SuspendedScreen, SubscriptionScreen
Promotions, Réservations, Freshness, SerialRecords, IntegrationsSettings

### 🔴 À SUPPRIMER (1 doublon)

- `daily_sales_page.dart` — doublon de SalesHistoryScreen filtré

### 🟡 À FUSIONNER (2 supports)

- `sessions_pending_screen` → tab dans Reports
- `sync_diagnostic_screen` → section Settings

---

## Drivers couverts (Trigger Map)

| Driver | Scénarios qui répondent |
|---|---|
| Perte de contrôle quand absent (Blandine) | 01, 03, 06, 09 |
| Visibilité temps réel | 01, 06, 09 |
| Vol et pertes non prouvables (Yempabou) | 04, 06, 07 |
| Maîtrise et validation (chaîne de confiance) | 03 |
| Professionnalisation factures (Vivien) | 02, 07 |

✅ Tous les drivers du Trigger Map sont couverts.

---

## Coverage check

- ✅ 40/40 pages cibles assignées (chaque page apparaît dans exactement 1 scénario)
- ✅ Persona PRIMARY (Blandine) couverte par 4 scénarios (01, 03, 06, 09)
- ✅ Top business goal (THE ENGINE — 3 testeurs actifs) couvert par scénarios 01, 02, 06
- ✅ 14 pages delta identifiées + outliné en détail
- ✅ Lien à l'audit code existant maintenu

---

## Étapes suivantes

1. **Design System Figma** — extraire tokens (couleurs, typo, spacing) du code Flutter, créer composants atomiques (Button, Card, Input, KPI tile, Empty state, Modal, Breadcrumb)
2. **Maquettes Figma des 14 deltas** en priorité, en utilisant les page specs comme brief
3. **Audit visuel des 32 "garder"** — vérifier qu'ils respectent le design system, ajuster si besoin
4. **Feature flags** pour cacher les 15 écrans hors-scope avant la démo testeurs
5. **Ré-implémentation Flutter** screen par screen depuis les maquettes Figma

---

## Documents liés

- **[Trigger Map](../B-Trigger-Map/00-trigger-map.md)** — Personas et drivers
- **[Brief Phase 1](../../_bmad-output/phase1-brief.md)** — Scope et modules
- **[PRD](../../docs/prd-scalario-retail-2026-04-06.md)** — 38 FRs, 9 Epics
- **[Architecture](../../docs/architecture-scalario-retail-2026-04-06.md)** — Stack technique
