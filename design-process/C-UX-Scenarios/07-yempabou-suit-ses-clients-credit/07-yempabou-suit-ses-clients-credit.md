# 07: Yempabou suit ses clients à crédit

**Project:** Scalario Retail Phase 1
**Created:** 2026-04-06

---

## Transaction (Q1)

Consulter la liste des clients qui doivent de l'argent, ouvrir une fiche client pour voir l'historique, encaisser un paiement crédit quand un client revient régler.

## Business Goal (Q2)

**Différenciation vs Gescom** + **Acquisition** — La vente à crédit + suivi crédits est une feature unique en Phase 1. C'est ce qui fait basculer Yempabou.

## User & Situation (Q3)

Yempabou, boutique boissons, mardi 11h. Un client habituel entre, dit "je viens régler ce que je devais". Yempabou doit retrouver son ardoise rapidement.

## Driving Forces (Q4)

**Hope:** Voir tous ses débiteurs en un coup d'œil, encaisser sans confusion, garder l'historique propre.
**Worry:** Oublier un crédit, perdre de l'argent, se tromper de client.

## Device & Starting Point (Q5 + Q6)

**Device:** Téléphone Android au comptoir.
**Entry:** Tape "Clients" depuis le menu principal.

## Best Outcome (Q7)

**User Success:** En 2 minutes : trouve le client (recherche par nom/téléphone), voit son solde dû (12 500 F), enregistre le paiement (8 000 F reçus en cash), nouveau solde 4 500 F affiché, ticket imprimé.

**Business Success:** Crédit suivi correctement, plus d'oublis, lock-in renforcé.

## Shortest Path (Q8)

1. **Liste clients (31)** — Recherche client, voit le solde dû.
2. **Fiche client (32)** — Détail historique achats + crédits en cours. Tape "Enregistrer paiement".
3. **Enregistrement paiement crédit (33)** — Saisit montant + mode paiement → confirmation. ✓

## Trigger Map Connections

**Persona:** Yempabou (SECONDARY)
**Want:** Preuves créances + mieux que Gescom
**Fear:** Perdre des crédits

## Scenario Steps

| Step | Folder | Purpose | Statut écran existant |
|------|--------|---------|---|
| 07.1 | `07.1-liste-clients/` | Liste tous les clients triés par solde | ✅ **GARDER** — ContactsScreen |
| 07.2 | `07.2-fiche-client/` | Détail client + historique + crédits | 🔧 **REFONTE** — actuellement éclaté dans client_order_detail |
| 07.3 | `07.3-paiement-credit/` | Enregistrer un paiement crédit | 🔧 **REFONTE** — actuellement un dialog, mérite une vraie page |
