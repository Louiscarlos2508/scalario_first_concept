# 08: Yempabou réceptionne une livraison

**Project:** Scalario Retail Phase 1
**Created:** 2026-04-06

---

## Transaction (Q1)

Gérer ses fournisseurs (liste, fiches, historique d'achats), enregistrer une réception de marchandise avec quantités réelles vs commandées, ajouter au stock automatiquement.

## Business Goal (Q2)

**Acquisition + Retention** — Trace complète de la chaîne d'approvisionnement, pas de stock entrant non tracé. Différenciateur vs cahier.

## User & Situation (Q3)

Yempabou, boutique boissons, mercredi matin 8h. Le livreur de chez "Brakina" arrive avec 15 cartons. Yempabou doit vérifier la livraison et l'enregistrer dans Scalario.

## Driving Forces (Q4)

**Hope:** Réception rapide, traçabilité complète, stock à jour automatiquement.
**Worry:** Recevoir moins que commandé sans s'en rendre compte, manquer un fournisseur.

## Device & Starting Point (Q5 + Q6)

**Device:** Téléphone Android sur le comptoir.
**Entry:** Tape "Fournisseurs" dans le menu principal.

## Best Outcome (Q7)

**User Success:** En 5 minutes : ouvre la fiche fournisseur Brakina, voit la commande en attente, tape "Réceptionner", coche les lignes reçues, ajuste 1 quantité (10 au lieu de 12), valide. Stock incrémenté + facture archivée.

**Business Success:** Trace complète, écarts livraison détectés, historique fournisseur enrichi.

## Shortest Path (Q8)

1. **Liste fournisseurs (26)** — Recherche fournisseur, voit la commande en attente.
2. **Fiche fournisseur (27)** — Détail + historique. Tape "Réceptionner livraison".
3. **Réception marchandise (28)** — Coche lignes, ajuste qtés, valide → stock à jour. ✓

## Trigger Map Connections

**Persona:** Yempabou (SECONDARY)
**Want:** Vue achats + preuves
**Fear:** Recevoir moins sans s'en rendre compte

## Scenario Steps

| Step | Folder | Purpose | Statut écran existant |
|------|--------|---------|---|
| 08.1 | `08.1-liste-fournisseurs/` | Catalogue fournisseurs filtrable | ❌ **CRÉER** — page absente (POs existent mais pas CRUD supplier) |
| 08.2 | `08.2-fiche-fournisseur/` | Détail fournisseur + historique commandes/réceptions | ❌ **CRÉER** |
| 08.3 | `08.3-reception-marchandise/` | Réception ligne par ligne avec écarts | 🔧 **REFONTE** — PurchaseOrderDetailScreen à valider/recadrer UX |
