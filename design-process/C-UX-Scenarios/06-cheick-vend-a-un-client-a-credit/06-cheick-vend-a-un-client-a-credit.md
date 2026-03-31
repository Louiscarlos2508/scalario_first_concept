---
design_intent: D
design_status: not-started
---

# 06 : Cheick Vend à un Client à Crédit

**Projet :** Scalario
**Créé :** 2026-03-31
**Méthode :** Whiteport Design Studio (WDS) — Phase 3 Scenarios

---

## Transaction (Q1)

**Ce que ce scénario couvre :**
Un client régulier de Cheick arrive. Avant d'encaisser, Cheick vérifie son solde de crédit. Il enregistre la vente et met à jour la créance du client en temps réel.

---

## Objectif Business (Q2)

**Objectif :** O2 — Créer des utilisateurs qui ne peuvent plus travailler sans Scalario
**SMART :** O2.1 — NRR > 100% à 12 mois
**Rôle :** Feature créances = switching cost Standard+ · une fois les clients et soldes dans Scalario, Cheick ne repart pas

---

## Utilisateur & Situation (Q3)

**Persona :** Cheick le Chimiste (Priorité 3 — Standard+)
**Situation :** Cheick, derrière son comptoir, en pleine journée de vente. Un client habituel arrive pour acheter à crédit comme d'habitude. Cheick ne se souvient pas exactement de son solde.

---

## Forces Motrices (Q4)

**Espoir :** Voir le solde exact du client en 2 secondes et encaisser (ou pas) en toute clarté — sans gêne, sans approximation.

**Crainte :** Laisser partir le client avec une créance non enregistrée parce qu'il a oublié de noter — comme avant.

---

## Appareil & Point d'Entrée (Q5 + Q6)

**Appareil :** Mobile
**Entrée :** Cheick est sur le POS, en train de servir. Le client habituel arrive. Il cherche son nom dans la liste clients directement depuis l'app.

---

## Meilleur Résultat (Q7)

**Succès Cheick :**
Il a vu le solde du client, enregistré la nouvelle vente à crédit, le solde est mis à jour — le tout en moins d'une minute devant le client.

**Succès business :**
Feature créances prouvée en conditions réelles → rétention Standard+ → NRR anchor → O2.1.

---

## Chemin le Plus Court (Q8)

1. **Clients — Liste** — Cheick cherche le nom du client habituel et le sélectionne
2. **Clients — Fiche + solde crédit** — Il voit le solde actuel, enregistre la nouvelle vente à crédit, le solde se met à jour ✓

---

## Connexions Trigger Map

**Persona :** Cheick le Chimiste (P3 Standard+)

**Forces motrices adressées :**
- ✅ **Want P2 :** Voir le solde de crédit d'un client au moment précis de la vente
- ❌ **Fear N2 :** Peur de ne jamais récupérer les créances clients

**Objectif business :** O2.1 — NRR > 100% · feature différenciante Standard+ vs Standard

---

## Étapes du Scénario

| Étape | Dossier | Objet | Action de sortie |
|-------|---------|-------|-----------------|
| 06.1 | `06.1-clients-liste/` | Cherche et sélectionne le client | Sélectionne → Fiche client |
| 06.2 | `06.2-clients-fiche-solde-credit/` | Vérifie solde, enregistre vente à crédit | Solde mis à jour → Fin ✓ |
