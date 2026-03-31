---
design_intent: S
design_status: not-started
---

# 03 : Bernard Découvre Scalario Seul

**Projet :** Scalario
**Créé :** 2026-03-31
**Méthode :** Whiteport Design Studio (WDS) — Phase 3 Scenarios

---

## Transaction (Q1)

**Ce que ce scénario couvre :**
Bernard a reçu un lien ou une démo d'un intégrateur. Il ouvre l'app pour la première fois, seul, sans aide. Il doit configurer sa boutique et faire sa première vente test — sans appeler personne.

---

## Objectif Business (Q2)

**Objectif :** O2 — Créer des utilisateurs qui ne peuvent plus travailler sans Scalario
**SMART :** O2.3 — 2 testeurs Standard en usage autonome sans Carlos dans les 2 premiers mois · Gate 2
**Rôle :** Validation que le Standard track est viable pour la masse du marché · archétype playbook intégrateur

---

## Utilisateur & Situation (Q3)

**Persona :** Bernard le Boutiquier (Priorité 2 — Standard)
**Situation :** Bernard est dans sa boutique de boissons à Ouagadougou, un soir après fermeture. L'intégrateur lui a montré une démo et lui a envoyé un lien de téléchargement. Il est seul avec son téléphone.

---

## Forces Motrices (Q4)

**Espoir :** Que ça marche du premier coup et qu'il arrive à configurer sa boutique tout seul en quelques minutes.

**Crainte :** Que ce soit trop compliqué — son réflexe habituel face à tout outil nouveau est d'arrêter à la première friction.

---

## Appareil & Point d'Entrée (Q5 + Q6)

**Appareil :** Mobile (desktop également possible selon contexte)
**Entrée :** L'intégrateur lui a partagé un lien de téléchargement ou un QR code après la démo. Bernard ouvre le lien, installe l'app, et arrive sur l'écran de démarrage.

---

## Meilleur Résultat (Q7)

**Succès Bernard :**
Il a configuré sa boutique et enregistré sa première vente test en moins de 10 minutes, seul. Il se dit : *"C'est simple, je peux l'utiliser."*

**Succès business :**
Onboarding Standard autonome validé → Gate 2 → playbook intégrateur confirmé → O2.3.

---

## Chemin le Plus Court (Q8)

1. **Splash / Loading** — L'app s'ouvre, Bernard voit l'écran de bienvenue Scalario
2. **Login** — Il crée son compte (ou se connecte avec le lien d'invitation de l'intégrateur)
3. **Onboarding Wizard** — Il configure sa boutique (nom, devise, 2-3 produits de base) et enregistre sa première vente test ✓

---

## Connexions Trigger Map

**Persona :** Bernard le Boutiquier (P2 Standard)

**Forces motrices adressées :**
- ✅ **Want P1 :** Fermer sa journée en < 5 minutes avec un chiffre fiable
- ❌ **Fear N1 :** Peur que l'outil soit trop compliqué pour lui et son employé

**Objectif business :** O2.3 — Testeurs autonomes < 2 mois · Gate 2 · validation modèle Standard

---

## Étapes du Scénario

| Étape | Dossier | Objet | Action de sortie |
|-------|---------|-------|-----------------|
| 03.1 | `03.1-splash/` | Première impression — l'app s'ouvre | Tape "Commencer" → Login |
| 03.2 | `03.2-login/` | Création de compte / invitation | Compte créé → Onboarding Wizard |
| 03.3 | `03.3-onboarding-wizard/` | Configure boutique + première vente test | Première valeur perçue ✓ |
