---
design_intent: L
design_status: not-started
---

# 09 : Blandine Ajuste Sa Configuration

**Projet :** Scalario
**Créé :** 2026-03-31
**Méthode :** Whiteport Design Studio (WDS) — Phase 3 Scenarios

---

## Transaction (Q1)

**Ce que ce scénario couvre :**
Le propriétaire veut ajuster sa configuration en cours d'utilisation : ajouter un employé, modifier un rôle, changer un paramètre. Il le fait depuis les vues de gestion — l'IA Config est disponible mais avec des confirmations explicites pour éviter les erreurs.

**Note design :** L'accès à l'IA Config est restreint par rôle et par type d'action. Guardrail volontaire : confirmation + prévisualisation avant toute application de changement.

---

## Objectif Business (Q2)

**Objectif :** O2 — Créer des utilisateurs qui ne peuvent plus travailler sans Scalario
**SMART :** O2.2 — Sessions actives > 5/semaine (configuration autonome = zéro appel support)
**Rôle :** Config bien gérée = équipe qui tourne sans friction = rétention durable

---

## Utilisateur & Situation (Q3)

**Persona :** Blandine la Boutiquière (Priorité 1 — Premium)
**Situation :** Blandine, depuis l'étranger sur son PC. Un nouvel employé vient d'être recruté à Ouagadougou. Elle doit créer son compte dans Scalario et lui assigner le bon rôle — depuis sa position à distance.

---

## Forces Motrices (Q4)

**Espoir :** Créer le compte du nouvel employé en 3 minutes depuis son PC, lui assigner le bon rôle, et qu'il puisse se connecter dès son premier jour sans que Blandine soit physiquement là.

**Crainte :** Lui donner accès à plus que ce qu'il devrait voir — ou valider un changement IA Config sans comprendre les conséquences.

---

## Appareil & Point d'Entrée (Q5 + Q6)

**Appareil :** Desktop
**Entrée :** Blandine est sur l'app depuis son PC. Elle navigue directement vers la gestion des utilisateurs depuis le menu.

---

## Meilleur Résultat (Q7)

**Succès Blandine :**
Le compte est créé, le rôle assigné avec les bonnes permissions — le nouvel employé peut se connecter dès son premier jour. Elle a fait ça en 5 minutes depuis l'étranger sans aucune aide.

**Succès business :**
Gestion utilisateurs autonome → zéro appel support Carlos → scalabilité opérationnelle.

---

## Chemin le Plus Court (Q8)

*Flow principal — ajout employé :*

1. **Utilisateurs — Liste + rôles** — Blandine voit son équipe actuelle, tape "Nouvel utilisateur"
2. **Utilisateurs — Création / édition rôle** — Elle saisit les infos, sélectionne le rôle (aperçu permissions), confirme ✓

*Flows indépendants documentés séparément :*
- Paramètres général (09.3)
- Paramètres intégrations (09.4)

---

## Connexions Trigger Map

**Persona :** Blandine la Boutiquière (P1 Premium)

**Forces motrices adressées :**
- ✅ **Want P1 :** Valider depuis son téléphone/PC sans se déplacer
- ❌ **Fear N3 :** Peur que l'outil résiste à l'adoption de ses 5 employés

**Objectif business :** O2.2 — Sessions > 5/semaine · autonomie de gestion · zéro support

---

## Étapes du Scénario

| Étape | Dossier | Objet | Action de sortie |
|-------|---------|-------|-----------------|
| 09.1 | `09.1-utilisateurs-liste-roles/` | Vue équipe → tape "Nouvel utilisateur" | → Création utilisateur |
| 09.2 | `09.2-utilisateurs-creation-edition/` | Crée compte + assigne rôle | Confirmé ✓ |
| 09.3 | `09.3-parametres-general/` | Paramètres généraux boutique | Indépendant |
| 09.4 | `09.4-parametres-integrations/` | Config intégrations (mobile money) | Indépendant |
