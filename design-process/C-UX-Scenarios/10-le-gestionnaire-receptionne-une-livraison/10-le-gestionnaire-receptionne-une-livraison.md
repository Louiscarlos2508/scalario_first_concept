---
design_intent: L
design_status: not-started
---

# 10 : Le Gestionnaire Réceptionne une Livraison

**Projet :** Scalario
**Créé :** 2026-03-31
**Méthode :** Whiteport Design Studio (WDS) — Phase 3 Scenarios

---

## Transaction (Q1)

**Ce que ce scénario couvre :**
Un fournisseur vient de livrer. Le gestionnaire réceptionne la marchandise dans Scalario : il enregistre les quantités reçues, note les pertes ou dégâts à la réception, et met à jour le stock. Pour les produits frais, le Taux de Frotte est appliqué automatiquement.

---

## Objectif Business (Q2)

**Objectif :** O2 — Créer des utilisateurs qui ne peuvent plus travailler sans Scalario
**SMART :** O2.2 — Sessions actives > 5/semaine (réception = événement quotidien tracé)
**Rôle :** Audit trail réception complet → preuve pour Blandine → rétention Premium

---

## Utilisateur & Situation (Q3)

**Persona :** Le Gestionnaire de Blandine (rôle terrain — acteur clé du workflow Premium)
**Situation :** Le gestionnaire est à la boutique à Ouagadougou. Un fournisseur vient d'arriver avec une livraison. Il doit tout enregistrer avant que Blandine demande les chiffres depuis l'étranger.

---

## Forces Motrices (Q4)

**Espoir :** Enregistrer la réception rapidement et correctement — pour que les chiffres que Blandine voit depuis l'étranger soient exacts dès la livraison.

**Crainte :** Faire une erreur de saisie ou oublier un article — et que Blandine lui demande des comptes sur un écart qu'il ne peut pas expliquer.

---

## Appareil & Point d'Entrée (Q5 + Q6)

**Appareil :** Mobile
**Entrée :** Le gestionnaire est à la boutique, livraison devant lui. Il ouvre l'app sur son téléphone et navigue directement vers le module de réception stock.

---

## Meilleur Résultat (Q7)

**Succès gestionnaire :**
La réception est enregistrée en 5 minutes — quantités, pertes à la réception, Taux de Frotte appliqué sur les produits frais. Le stock est à jour, Blandine voit les chiffres corrects depuis l'étranger.

**Succès business :**
Audit trail réception complet → preuve pour Blandine → rétention Premium → O2.2.

---

## Chemin le Plus Court (Q8)

1. **Stock — Réception marchandise** — Le gestionnaire sélectionne le fournisseur, saisit les quantités reçues par produit, note les pertes/dégâts, confirme la réception (Taux de Frotte appliqué automatiquement sur produits frais)
2. **Stock — Inventaire / Ajustement** — Il vérifie que le stock mis à jour reflète bien la réception, ajuste si nécessaire ✓

---

## Connexions Trigger Map

**Persona :** Blandine la Boutiquière (P1 Premium) — via son gestionnaire terrain

**Forces motrices adressées :**
- ✅ **Want P2 :** Avoir la preuve de qui a fait quoi, dans quelle phase
- ✅ **Want P3 :** Distinguer perte naturelle (Frotte) de vol ou négligence
- ❌ **Fear N1 :** Peur de ne jamais savoir si ses pertes sont du vol, de la négligence ou de la nature

**Objectif business :** O2.2 — Sessions > 5/semaine · audit trail complet · rétention Premium

---

## Étapes du Scénario

| Étape | Dossier | Objet | Action de sortie |
|-------|---------|-------|-----------------|
| 10.1 | `10.1-stock-reception-marchandise/` | Saisit réception + pertes + Frotte auto | Confirmé → Inventaire |
| 10.2 | `10.2-stock-inventaire-ajustement/` | Vérifie stock mis à jour, ajuste si besoin | Stock exact ✓ |
