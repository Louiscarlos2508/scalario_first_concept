---
design_intent: S
design_status: not-started
---

# 02 : Blandine Surveille Sa Boutique à Distance

**Projet :** Scalario
**Créé :** 2026-03-31
**Méthode :** Whiteport Design Studio (WDS) — Phase 3 Scenarios

---

## Transaction (Q1)

**Ce que ce scénario couvre :**
Blandine est à l'étranger. Elle ouvre l'app pour prendre le pouls de sa boutique — sans qu'on lui ait rien demandé. Elle scanne les chiffres clés et agit sur une alerte en suspens.

---

## Objectif Business (Q2)

**Objectif :** O2 — Créer des utilisateurs qui ne peuvent plus travailler sans Scalario
**SMART :** O2.2 — Sessions actives > 5/semaine par client à 3 mois (adoption réelle)
**Rôle :** Usage proactif quotidien → rétention → NRR > 100%

---

## Utilisateur & Situation (Q3)

**Persona :** Blandine la Boutiquière (Priorité 1 — Premium)
**Situation :** Blandine est à l'étranger, sur son PC, milieu d'après-midi heure locale. Pas de notification reçue — elle ouvre l'app de sa propre initiative entre deux obligations pour vérifier que tout tourne bien à Ouagadougou.

---

## Forces Motrices (Q4)

**Espoir :** Voir en un coup d'œil que la journée avance bien — CA en cours, stock stable, rien d'anormal.

**Crainte :** Tomber sur un chiffre qui ne tient pas et réaliser que son gestionnaire ne l'a pas prévenue.

---

## Appareil & Point d'Entrée (Q5 + Q6)

**Appareil :** Desktop (PC)
**Entrée :** Elle est sur son PC, entre deux obligations. Soit elle ouvre l'app directement (signet ou app desktop), soit un résumé WhatsApp automatique (CA en cours, alerte stock) attire son attention. Dans les deux cas elle arrive sur son dashboard propriétaire.

---

## Meilleur Résultat (Q7)

**Succès Blandine :**
En 2 minutes elle sait que sa boutique tourne normalement, elle a vu et traité une alerte — elle repart sans avoir eu à appeler personne.

**Succès business :**
Usage proactif quotidien prouvé → O2.2 sessions > 5/semaine → argument rétention Premium.

---

## Chemin le Plus Court (Q8)

1. **Dashboard Propriétaire** — Elle scanne les chiffres clés (CA du jour, mouvements stock, statut employés) et repère une alerte en suspens
2. **Centre d'alertes** — Elle ouvre l'alerte, comprend ce qui s'est passé et la marque comme traitée ✓

---

## Connexions Trigger Map

**Persona :** Blandine la Boutiquière (P1 Premium)

**Forces motrices adressées :**
- ✅ **Want P1 :** Valider depuis son téléphone/PC sans se déplacer
- ✅ **Want P5 :** Recevoir un résumé WhatsApp qui filtre ce qui nécessite son attention
- ❌ **Fear N2 :** Anxiété d'apprendre que "tout va bien" alors que ce n'est pas le cas

**Objectif business :** O2.2 — Sessions > 5/semaine · adoption prouvée · rétention Premium

---

## Étapes du Scénario

| Étape | Dossier | Objet | Action de sortie |
|-------|---------|-------|-----------------|
| 02.1 | `02.1-dashboard-proprietaire/` | Scanner les chiffres clés et repérer une alerte | Clique sur l'alerte → Centre alertes |
| 02.2 | `02.2-centre-alertes/` | Comprendre et traiter l'alerte | Marque comme traitée → Fin ✓ |
