---
design_intent: D
design_status: not-started
---

# 07 : Cheick Agit Sur Ses Péremptions

**Projet :** Scalario
**Créé :** 2026-03-31
**Méthode :** Whiteport Design Studio (WDS) — Phase 3 Scenarios

---

## Transaction (Q1)

**Ce que ce scénario couvre :**
Cheick reçoit une notification — un produit approche de sa date d'expiration. Il ouvre le tableau de bord péremptions, identifie les produits à risque et décide quoi faire avant que la perte soit inévitable.

---

## Objectif Business (Q2)

**Objectif :** O2 — Créer des utilisateurs qui ne peuvent plus travailler sans Scalario
**SMART :** O2.1 — NRR > 100% à 12 mois
**Rôle :** Alertes péremption = usage proactif déclenché → rétention Standard+ · référence sectorielle cosmétique

---

## Utilisateur & Situation (Q3)

**Persona :** Cheick le Chimiste (Priorité 3 — Standard+)
**Situation :** Cheick, dans sa boutique ou chez lui. Il reçoit une notification push — un produit expire dans 14 jours. Il ouvre l'app pour voir ce qui est concerné.

---

## Forces Motrices (Q4)

**Espoir :** Voir exactement quels produits sont à risque et avoir le temps de les solder avant expiration — agir avant la perte, pas après.

**Crainte :** Découvrir que plusieurs produits ont expiré sans qu'il ait été prévenu — perte sèche, stock inutilisable.

---

## Appareil & Point d'Entrée (Q5 + Q6)

**Appareil :** Mobile
**Entrée :** Il reçoit une notification push : "3 produits expirent dans moins de 14 jours." Il tape sur la notification → l'app s'ouvre directement sur le tableau de bord péremptions.

---

## Meilleur Résultat (Q7)

**Succès Cheick :**
Il a vu les 3 produits à risque, décidé de les mettre en promotion pour les écouler — tout en moins de 3 minutes. Aucune perte sur ces produits.

**Succès business :**
Usage proactif déclenché par alerte → rétention Standard+ → référence sectorielle cosmétique.

---

## Chemin le Plus Court (Q8)

1. **Péremptions — Tableau de bord** — Cheick voit la liste des produits classés par urgence (J-14, J-7, expirés), identifie les produits à risque et marque une action (promotion / retrait) ✓

---

## Connexions Trigger Map

**Persona :** Cheick le Chimiste (P3 Standard+)

**Forces motrices adressées :**
- ✅ **Want P3 :** Être alerté sur les produits qui approchent de leur péremption avant qu'il soit trop tard
- ❌ **Fear N3 :** Peur de trouver des produits expirés qu'il n'a pas remarqués — donc non vendus et perdus

**Objectif business :** O2.1 — NRR > 100% · usage proactif · rétention Standard+

---

## Étapes du Scénario

| Étape | Dossier | Objet | Action de sortie |
|-------|---------|-------|-----------------|
| 07.1 | `07.1-peremptions-tableau-de-bord/` | Voir produits à risque + décider action | Action marquée → Fin ✓ |
