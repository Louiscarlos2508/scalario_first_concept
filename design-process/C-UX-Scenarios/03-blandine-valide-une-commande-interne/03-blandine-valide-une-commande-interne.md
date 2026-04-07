# 03: Blandine valide une commande interne

**Project:** Scalario Retail Phase 1
**Created:** 2026-04-06

---

## Transaction (Q1)

Le commercial constate un stock bas → crée une demande de commande interne → la gérante approuve → la patronne valide ou refuse → historique tracé.

## Business Goal (Q2)

**Différenciation vs Gescom** + **Blandine PRIMARY** — Le circuit de validation est LA réponse au "rien sans mon accord". Différenciateur clé.

## User & Situation (Q3)

Blandine, depuis Dakar, ouvre la notif "1 commande à valider". Le commercial à Ouaga a constaté qu'il manque des oignons. La gérante a déjà approuvé. Blandine doit valider ou refuser avec motif.

## Driving Forces (Q4)

**Hope:** Décider en 1 tap, voir tout l'historique de la demande, garder la maîtrise.
**Worry:** Approuver à l'aveugle, ne pas savoir qui a demandé quoi.

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android.
**Entry:** Notification push "Commande à valider" → tap → liste commandes.

## Best Outcome (Q7)

**User Success:** En 90 secondes : voit la commande, lit le motif du commercial, vérifie l'historique, valide → notification commercial + gérante.
**Business Success:** Audit trail complet, validation rapide, lock-in maîtrise.

## Shortest Path (Q8)

1. **Liste commandes (23)** — Filtre "À valider", tape la commande.
2. **Création/détail commande (24)** — Lecture détail (qui, quoi, motif, historique).
3. **Validation commande (25)** — Boutons Valider / Refuser avec motif. ✓

## Trigger Map Connections

**Persona:** Blandine (PRIMARY)
**Want:** Maîtrise + chaîne de confiance
**Fear:** Décisions sans elle

## Scenario Steps

| Step | Folder | Purpose | Statut écran existant |
|------|--------|---------|---|
| 03.1 | `03.1-liste-commandes/` | Liste demandes filtrables | ✅ **GARDER** — ClientOrdersScreen |
| 03.2 | `03.2-creation-commande/` | Création commercial / lecture détail | ✅ **GARDER** — ClientOrderFormScreen |
| 03.3 | `03.3-validation-commande/` | Approuver/refuser avec motif | ✅ **GARDER** — ClientOrderDetailScreen |

**Note:** Tous les écrans existent et sont validés. Aucune refonte nécessaire pour ce scénario.
