# 05: Yempabou clôture sa caisse

**Project:** Scalario Retail Phase 1
**Created:** 2026-04-06

---

## Transaction (Q1)

Faire l'arrêt de caisse en fin de journée — comparer le montant théorique (calculé sur les ventes) et le montant réel compté en caisse, voir l'écart immédiatement, ventiler par mode de paiement, transmettre au patron.

## Business Goal (Q2)

**RETENTION** — Routine quotidienne ancrée. Si l'arrêt de caisse Scalario est plus rapide et clair que compter à la main + écrire dans le cahier, la routine s'installe immédiatement.

## User & Situation (Q3)

Yempabou (ou sa gérante), boutique boissons, vendredi 19h45, fermeture imminente. Tiroir caisse ouvert, billets et pièces sur le comptoir. Téléphone en main. Il veut savoir en moins de 5 minutes si le compte est bon.

## Driving Forces (Q4)

**Hope:** Voir tout de suite si la caisse colle, partir l'esprit tranquille.
**Worry:** Découvrir un manque qu'il devra justifier au patron, ou ne pas comprendre d'où vient l'écart.

## Device & Starting Point (Q5 + Q6)

**Device:** Téléphone Android sur le comptoir.
**Entry:** Tape "Caisse" depuis le menu principal → Caisse ouverte (vue session active).

## Best Outcome (Q7)

**User Success:** En 4 minutes : vue de la caisse en cours → tape "Clôturer", saisit le montant réel par mode de paiement, voit l'écart calculé en live (Cash -500 F, Wave OK, OM OK). Valide → arrêt envoyé au patron.

**Business Success:** Audit trail complet (cashier → manager → owner). Routine adoptée. Différenciation vs cahier (qui ne ventile pas par mode).

## Shortest Path (Q8)

1. **Caisse ouverte (20)** — Voit la session en cours, total ventes du jour, ventilation par mode. Tape "Clôturer la caisse".
2. **Arrêt de caisse (21)** — Saisit montants réels par mode → écarts calculés en live → tape "Valider".
3. **Historique arrêts (22)** — Confirmation visuelle de l'arrêt archivé + status en attente patron. ✓

## Trigger Map Connections

**Persona:** Yempabou (SECONDARY)
**Want:** Réconciliation argent / preuves
**Fear:** Dépendance à l'appel / écarts non expliqués
**Goal:** RETENTION + 0 perte de données

## Scenario Steps

| Step | Folder | Purpose | Statut écran existant |
|------|--------|---------|---|
| 05.1 | `05.1-caisse-ouverte/` | Vue de la session active + déclenchement clôture | 🔧 **REFONTE** — UnifiedSessionsScreen à recadrer |
| 05.2 | `05.2-arret-de-caisse/` | Saisie montants réels + calcul écart | ✅ **GARDER** — SessionCloseScreen validé |
| 05.3 | `05.3-historique-arrets/` | Confirmation + historique | ✅ **GARDER** — SessionHistoryScreen validé |
