# 04: Yempabou démasque les pertes (inventaire hebdo)

**Project:** Scalario Retail Phase 1
**Created:** 2026-04-06
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

Lancer un inventaire hebdomadaire physique, saisir les quantités réelles produit par produit, voir les écarts en clair (surtout les négatifs = vol/pertes), et faire valider le résultat par le patron.

---

## Business Goal (Q2)

**Goal:** RETENTION — Lock-in via preuves tangibles
**Objective:** Yempabou ne peut PAS prouver le vol avec son cahier. Avec Scalario, l'écart négatif d'inventaire devient un chiffre incontestable. C'est le moment "aha" qui rend impossible le retour à l'ancien outil.

---

## User & Situation (Q3)

**Persona:** Yempabou (SECONDARY)
**Situation:** Patron pragmatique, boutique boissons/divers à Ouaga, ~150 produits. Dimanche soir 20h, boutique fermée, sa gérante (membre famille) l'aide. Téléphone en main, ils passent rayon par rayon, comptent et saisissent.

---

## Driving Forces (Q4)

**Hope:** Voir enfin des chiffres précis sur ce qui manque, pouvoir confronter les vendeurs avec des preuves.

**Worry:** Découvrir des écarts énormes sans pouvoir identifier la source, ou pire — ne rien voir parce que l'outil est compliqué.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Téléphone Android (rapide à manipuler dans les rayons)
**Entry:** Yempabou ouvre l'app, profil patron actif, tape "Inventaire" dans le menu principal → Liste inventaires.

---

## Best Outcome (Q7)

**User Success:**
En 45 minutes, les 150 produits sont comptés. Le résumé affiche : 12 produits avec écart négatif (valeur 18 500 F), 3 avec écart positif. Yempabou voit immédiatement le top 5 des pertes. Il valide l'inventaire, le résultat est archivé et envoyé au cloud.

**Business Success:**
Lock-in confirmé — Yempabou ne peut plus revenir au cahier. Routine hebdomadaire ancrée. Différenciateur clé vs Gescom (qui ne fait pas d'inventaire structuré).

---

## Shortest Path (Q8)

1. **Liste inventaires (17)** — Tape "Nouvel inventaire" → choix du périmètre (tous produits / catégorie).
2. **Inventaire en cours (18)** — Saisie quantités réelles produit par produit, écarts calculés en live.
3. **Résultat inventaire (19)** — Récap : nb écarts, valeur totale, top 5 négatifs. Tape "Valider et envoyer au patron". ✓

---

## Trigger Map Connections

**Persona:** Yempabou (SECONDARY)

**Driving Forces Addressed:**
- ✅ **Want:** Preuves tangibles + mieux que Gescom
- ❌ **Fear:** Vol et pertes non prouvables

**Business Goal:** RETENTION — abandon ancien outil <2 semaines, lock-in via preuves

---

## Scenario Steps

| Step | Folder | Purpose | Statut écran existant |
|------|--------|---------|---|
| 04.1 | `04.1-liste-inventaires/` | Lancer ou consulter un inventaire | 🔧 **REFONTE** — InternalRequestsScreen mal nommé/positionné |
| 04.2 | `04.2-inventaire-en-cours/` | Compter et saisir les écarts | ✅ **GARDER** — InventoryCountScreen validé |
| 04.3 | `04.3-resultat-inventaire/` | Voir les écarts, valider, archiver | ❌ **CRÉER** — page absente |
