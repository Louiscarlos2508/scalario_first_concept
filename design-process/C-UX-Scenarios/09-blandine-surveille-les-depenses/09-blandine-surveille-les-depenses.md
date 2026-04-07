# 09: Blandine surveille les dépenses

**Project:** Scalario Retail Phase 1
**Created:** 2026-04-06

---

## Transaction (Q1)

La gérante saisit une dépense ad hoc (transport, eau, sac plastique, réparation). Le patron voit immédiatement la dépense dans l'historique et peut la valider/refuser.

## Business Goal (Q2)

**Visibilité financière** — Marge réelle calculable. Différenciation vs cahier qui ne sépare pas CA et dépenses.

## User & Situation (Q3)

Côté gérante : besoin urgent d'eau pour les clients, achat 2 000 F. Elle saisit la dépense.
Côté Blandine : depuis Dakar, voit la dépense apparaître dans le rapport.

## Driving Forces (Q4)

**Hope (gérante):** Saisir vite, prouver l'achat avec photo facture/reçu.
**Hope (Blandine):** Tout savoir sur ce qui sort de la caisse.
**Fear (Blandine):** Argent qui sort sans être tracé.

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android (gérante au comptoir).
**Entry:** Menu → "Dépenses" → "+ Nouvelle dépense".

## Best Outcome (Q7)

**User Success:** En 30 secondes : catégorie + montant + photo reçu + valider. Dépense visible côté patron immédiatement.

## Shortest Path (Q8)

1. **Liste dépenses (29)** — Voit l'historique, tape "+ Nouvelle".
2. **Saisie dépense (30)** — Formulaire rapide → valider. ✓

## Trigger Map Connections

**Persona:** Blandine (PRIMARY) + gérante comme acteur
**Want:** Visibilité totale
**Fear:** Argent sortant sans contrôle

## Scenario Steps

| Step | Folder | Purpose | Statut écran existant |
|------|--------|---------|---|
| 09.1 | `09.1-liste-depenses/` | Historique dépenses + filtres | ✅ **GARDER** — ExpensesScreen |
| 09.2 | `09.2-saisie-depense/` | Formulaire saisie rapide | ✅ **GARDER** — formulaire intégré dans ExpensesScreen |

**Note:** Aucune refonte nécessaire. Vérifier que la photo reçu est bien implémentée et que la liste filtre par catégorie.
