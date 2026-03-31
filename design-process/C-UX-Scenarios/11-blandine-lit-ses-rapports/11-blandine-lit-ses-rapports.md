---
design_intent: L
design_status: not-started
---

# 11 : Blandine Lit Ses Rapports

**Projet :** Scalario
**Créé :** 2026-03-31
**Méthode :** Whiteport Design Studio (WDS) — Phase 3 Scenarios

---

## Transaction (Q1)

**Ce que ce scénario couvre :**
Blandine veut comprendre comment sa boutique a performé sur la semaine — ventes, stock, pertes. Elle consulte ses rapports depuis son PC et pose des questions spécifiques en langage naturel pour obtenir des réponses directes sans naviguer dans des filtres complexes.

---

## Objectif Business (Q2)

**Objectif :** O2 — Créer des utilisateurs qui ne peuvent plus travailler sans Scalario
**SMART :** O2.1 — NRR > 100% (upsell naturel via analytics)
**Rôle :** Usage analytique hebdomadaire → engagement Premium → vecteur upsell modules avancés

---

## Utilisateur & Situation (Q3)

**Persona :** Blandine la Boutiquière (Priorité 1 — Premium)
**Situation :** Blandine est à l'étranger sur son PC, début de semaine. Elle prend le temps de regarder les chiffres de la semaine écoulée — pas en urgence, en mode analyse. Elle peut poser des questions spécifiques ("Quels produits ont le plus bougé ?", "Quel employé a fait le plus de ventes ?") et obtenir des réponses directes.

---

## Forces Motrices (Q4)

**Espoir :** Poser ses questions en langage naturel et obtenir des réponses claires — comprendre sa semaine en 10 minutes sans devoir appeler son gestionnaire.

**Crainte :** Voir des chiffres sans comprendre ce qu'ils signifient — ou ne pas savoir quoi chercher et passer à côté d'un problème.

---

## Appareil & Point d'Entrée (Q5 + Q6)

**Appareil :** Desktop
**Entrée :** Blandine ouvre l'app depuis son PC, navigue directement vers la section Rapports depuis son dashboard propriétaire.

---

## Meilleur Résultat (Q7)

**Succès Blandine :**
Elle a posé 3 questions, obtenu des réponses visuelles claires — elle comprend sa semaine, a identifié un produit à réapprovisionner, et repart avec une décision concrète. Sans appeler personne.

**Succès business :**
Usage analytique hebdomadaire → engagement Premium → vecteur upsell modules avancés → O2.1 NRR > 100%.

---

## Chemin le Plus Court (Q8)

1. **Rapports — Ventes** — Blandine consulte le CA de la semaine, pose une question GenUI ("Quel produit a le plus vendu ?") → obtient liste + graphique générés
2. **Rapports — Stock** — Elle consulte les mouvements stock, pose une question ("Qu'est-ce qui est à réapprovisionner ?") → obtient une liste priorisée, prend sa décision ✓

---

## Note Design Clé — GenUI Analytics

Blandine peut demander n'importe quel format de réponse : liste, graphique, tableau comparatif, tendance, classement. La GenUI génère la visualisation adaptée à sa question — elle n'est pas limitée par des vues prédéfinies. C'est le différenciateur Premium analytics de Scalario.

---

## Connexions Trigger Map

**Persona :** Blandine la Boutiquière (P1 Premium)

**Forces motrices adressées :**
- ✅ **Want P1 :** Valider depuis son PC sans se déplacer
- ✅ **Want P2 :** Avoir la preuve de qui a fait quoi (données ventes par employé)
- ❌ **Fear N2 :** Anxiété d'apprendre que "tout va bien" alors que ce n'est pas le cas

**Objectif business :** O2.1 — NRR > 100% · engagement analytique · upsell Premium

---

## Étapes du Scénario

| Étape | Dossier | Objet | Action de sortie |
|-------|---------|-------|-----------------|
| 11.1 | `11.1-rapports-ventes/` | CA semaine + question GenUI ventes | → Rapports Stock |
| 11.2 | `11.2-rapports-stock/` | Mouvements stock + question GenUI réappro | Décision prise ✓ |
