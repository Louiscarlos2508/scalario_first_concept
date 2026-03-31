---
design_intent: D
design_status: not-started
---

# 08 : Ibrahim Déploie Son Premier Client

**Projet :** Scalario
**Créé :** 2026-03-31
**Méthode :** Whiteport Design Studio (WDS) — Phase 3 Scenarios

---

## Transaction (Q1)

**Ce que ce scénario couvre :**
Ibrahim a convaincu un commerçant d'adopter Scalario. Il doit configurer son tenant de A à Z — produits, rôles, paramètres — en moins d'une journée, sans appeler Carlos.

---

## Objectif Business (Q2)

**Objectif :** O3 — Construire un canal de distribution qui scale sans Carlos
**SMART :** O3.1 — 1er client signé par un intégrateur sans Carlos au closing · Gate 5
**Rôle :** Validation canal intégrateur autonome → playbook reproductible → O3.2 + O3.3

---

## Utilisateur & Situation (Q3)

**Persona :** Ibrahim l'Intégrateur (Priorité 4 — Partenaire H2)
**Situation :** Ibrahim, formateur IT freelance à Ouagadougou. Il est chez son client commerçant pour le déploiement. C'est son premier client Scalario — son test réel. Si ça marche, il signe les 5 suivants.

---

## Forces Motrices (Q4)

**Espoir :** Finir la configuration complète en une demi-journée, voir son client utiliser l'app seul avant de partir — et recevoir sa première commission dans 30 jours.

**Crainte :** Bloquer sur une étape technique qu'il ne maîtrise pas et devoir appeler Carlos devant son client — sa crédibilité d'expert en prend un coup.

---

## Appareil & Point d'Entrée (Q5 + Q6)

**Appareil :** Desktop
**Entrée :** Ibrahim a reçu ses accès intégrateur de Carlos lors de sa formation. Il ouvre l'AI Config Wizard depuis son dashboard intégrateur — accès direct.

---

## Meilleur Résultat (Q7)

**Succès Ibrahim :**
Le tenant est configuré en moins d'une journée, son client a fait sa première vente test avant qu'Ibrahim parte — sans aide. Ibrahim repart avec une référence et attend sa première commission.

**Succès business :**
Canal intégrateur autonome validé → Gate 5 → O3.1 · playbook reproductible pour les 2 intégrateurs suivants.

---

## Chemin le Plus Court (Q8)

1. **AI Config Wizard** — Ibrahim configure le tenant de A à Z guidé par l'assistant : boutique, produits, rôles employés, paramètres paiement
2. **Dashboard Intégrateur** — Il vérifie que le tenant est actif, voit son client apparaître dans sa liste, confirme le déploiement réussi ✓

---

## Connexions Trigger Map

**Persona :** Ibrahim l'Intégrateur (P4 Partenaire H2)

**Forces motrices adressées :**
- ✅ **Want P1 :** Déployer et configurer un tenant complet en moins d'une journée
- ❌ **Fear N1 :** Peur que son client n'adopte pas le produit et le tienne pour responsable
- ❌ **Fear N2 :** Peur de ne pas savoir répondre à une question technique devant son client

**Objectif business :** O3.1 — Gate 5 · canal intégrateur autonome · playbook scalable

---

## Étapes du Scénario

| Étape | Dossier | Objet | Action de sortie |
|-------|---------|-------|-----------------|
| 08.1 | `08.1-ai-config-wizard/` | Configuration tenant guidée A à Z | Wizard complété → Dashboard |
| 08.2 | `08.2-dashboard-integrateur/` | Vérifie déploiement actif + client dans sa liste | Déploiement confirmé ✓ |
