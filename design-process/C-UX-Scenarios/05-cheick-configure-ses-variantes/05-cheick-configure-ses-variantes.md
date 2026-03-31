---
design_intent: D
design_status: not-started
---

# 05 : Cheick Configure Ses Variantes

**Projet :** Scalario
**Créé :** 2026-03-31
**Méthode :** Whiteport Design Studio (WDS) — Phase 3 Scenarios

---

## Transaction (Q1)

**Ce que ce scénario couvre :**
Cheick ouvre Scalario avec son catalogue en tête. Il crée un produit — "Nivea 200ml" — et configure ses 10 variantes (parfum, format, taille). Si l'outil comprend ses variantes, il n'a plus besoin d'un autre outil pour ça.

---

## Objectif Business (Q2)

**Objectif :** O2 — Créer des utilisateurs qui ne peuvent plus travailler sans Scalario
**SMART :** O2.1 — NRR > 100% à 12 mois (upsell naturel = croissance sans acquisition)
**Rôle :** Switching cost naturel via configuration variantes → Cheick anchor NRR Standard+

---

## Utilisateur & Situation (Q3)

**Persona :** Cheick le Chimiste (Priorité 3 — Standard+)
**Situation :** Cheick, dans sa boutique de cosmétiques à Ouagadougou. Il décide de configurer son catalogue quand il en a le temps. Il travaille depuis sa propre connaissance de ses produits, avec ou sans outil de référence à côté.

---

## Forces Motrices (Q4)

**Espoir :** Que Scalario comprenne la différence entre "Nivea 200ml parfum fleur" et "Nivea 200ml parfum océan" — et qu'il n'ait plus à gérer ça manuellement.

**Crainte :** Que l'outil ne supporte pas ses variantes et le force à créer 10 produits séparés — pire que ce qu'il avait avant.

---

## Appareil & Point d'Entrée (Q5 + Q6)

**Appareil :** Desktop
**Entrée :** Cheick a déjà un compte Scalario (testeur actif). Il ouvre l'app et va directement dans la gestion des produits pour configurer son catalogue.

---

## Meilleur Résultat (Q7)

**Succès Cheick :**
Il a créé "Nivea 200ml" avec ses 10 variantes, chaque SKU avec son stock initial. Il consulte la liste — tout est là, exactement comme dans sa tête. Il n'a plus besoin d'un autre outil pour ça.

**Succès business :**
Variantes validées → Cheick adopte → switching cost naturel → NRR anchor Standard+ → O2.1.

---

## Chemin le Plus Court (Q8)

1. **Produits — Liste catalogue** — Cheick voit son catalogue vide (ou partiel), tape "Nouveau produit"
2. **Produits — Création/édition** — Il nomme le produit, définit l'unité et le prix de base
3. **Variantes — Gestion multi-SKU** — Il ajoute ses attributs (parfum, format) et génère les 10 combinaisons SKU
4. **Stock — Fiche produit + variantes** — Il voit le produit complet avec ses variantes, saisit le stock initial par SKU ✓

---

## Connexions Trigger Map

**Persona :** Cheick le Chimiste (P3 Standard+)

**Forces motrices adressées :**
- ✅ **Want P1 :** Savoir exactement ce qu'il a de chaque référence sans compter physiquement
- ❌ **Fear N1 :** Peur de vendre une variante épuisée et de décevoir un client fidèle

**Objectif business :** O2.1 — NRR > 100% · switching cost naturel · anchor Standard+

---

## Étapes du Scénario

| Étape | Dossier | Objet | Action de sortie |
|-------|---------|-------|-----------------|
| 05.1 | `05.1-produits-liste-catalogue/` | Vue catalogue existant | Tape "Nouveau produit" → Création |
| 05.2 | `05.2-produits-creation-edition/` | Définit nom, unité, prix de base | Tape "Ajouter variantes" → Variantes |
| 05.3 | `05.3-variantes-gestion-multi-sku/` | Configure attributs + génère SKUs | Valide → Fiche produit |
| 05.4 | `05.4-stock-fiche-produit-variantes/` | Vérifie produit complet, saisit stock initial | Fin — catalogue prêt ✓ |
