# 06: Blandine pilote son stock frais

**Project:** Scalario Retail Phase 1
**Created:** 2026-04-06

---

## Transaction (Q1)

Consulter la liste produits, ajouter/modifier un produit (avec son prix, sa frotte, ses unités, sa fraîcheur), surveiller les alertes stock bas et les mouvements suspects.

## Business Goal (Q2)

**THE ENGINE** — Blandine doit avoir une vue parfaite de son stock frais depuis Dakar. C'est ce qui justifie le palier Pro à 15K FCFA.

## User & Situation (Q3)

Blandine, depuis Dakar, dimanche soir. Sa gérante lui a appelé pour signaler une livraison reçue. Elle veut ajouter les nouveaux produits + ajuster les prix de saison + vérifier ce qui sort beaucoup.

## Driving Forces (Q4)

**Hope:** Avoir un catalogue produits propre, des prix corrects, et anticiper les pertes.
**Worry:** Ne pas savoir ce qu'il y a en rayon, jeter des produits faute de visibilité fraîcheur.

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile + occasionnellement Desktop (depuis Dakar quand assise au PC).
**Entry:** Tape "Produits" depuis le menu principal.

## Best Outcome (Q7)

**User Success:** En 10 minutes : ajoute 3 nouveaux produits (avec photo, prix détail/gros, frotte 5%, péremption 7j), ajuste 2 prix, voit que 4 produits sont en alerte stock bas et 2 en fraîcheur rouge.

**Business Success:** Catalogue à jour, alertes pertinentes, différenciateur frais/frotte/vrac actif.

## Shortest Path (Q8)

1. **Liste produits (12)** — Recherche, filtre catégorie + statut. Tape "+" pour créer.
2. **Création/édition produit (14)** — Formulaire complet (infos + prix + frotte + vrac→sachet + fraîcheur).
3. **Fiche produit (13)** — Vue détail post-création, voit les mouvements.
4. **Mouvements stock (16)** — Tape "Voir tous les mouvements" pour creuser.
5. **Alertes stock (15)** — Retour menu → alertes. ✓

## Trigger Map Connections

**Persona:** Blandine (PRIMARY)
**Want:** Maîtrise + frotte/fraîcheur
**Fear:** Jeter sans savoir + flou stock
**Goal:** THE ENGINE

## Scenario Steps

| Step | Folder | Purpose | Statut écran existant |
|------|--------|---------|---|
| 06.1 | `06.1-liste-produits/` | Catalogue produits filtrable | 🔧 **REFONTE** — CategoriesScreen → vraie liste produits |
| 06.2 | `06.2-fiche-produit/` | Détail produit + mouvements | ✅ **GARDER** — ProductStockScreen |
| 06.3 | `06.3-creation-produit/` | Formulaire ajout/édition | ❌ **CRÉER** — page absente |
| 06.4 | `06.4-alertes-stock/` | Liste produits en alerte | ✅ **GARDER** — StockAlertsScreen |
| 06.5 | `06.5-mouvements-stock/` | Historique entrées/sorties/ajustements | 🔧 **REFONTE** — StockViewPage à recadrer |
