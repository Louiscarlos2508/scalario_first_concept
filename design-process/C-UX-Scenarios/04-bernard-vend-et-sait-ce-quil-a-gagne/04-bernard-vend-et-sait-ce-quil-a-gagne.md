---
design_intent: S
design_status: not-started
---

# 04 : Bernard Vend et Sait Ce Qu'il a Gagné

**Projet :** Scalario
**Créé :** 2026-03-31
**Méthode :** Whiteport Design Studio (WDS) — Phase 3 Scenarios

---

## Transaction (Q1)

**Ce que ce scénario couvre :**
Bernard ouvre sa boutique. Tout au long de la journée ses employés et lui encaissent des ventes sur le POS. Le soir, il sait exactement combien il a fait et ce qu'il lui reste en stock — sans compter physiquement.

---

## Objectif Business (Q2)

**Objectif :** O1 — Générer un revenu récurrent viable
**SMART :** O1.2 — Atteindre 10 clients payants actifs, ARR 3–4M FCFA, rétention > 70%
**Rôle :** Usage quotidien → rétention Standard → volume marché UEMOA

---

## Utilisateur & Situation (Q3)

**Persona :** Bernard le Boutiquier (Priorité 2 — Standard)
**Situation :** Bernard, boutique de boissons à Ouagadougou, journée normale. Parfois il est sur place, parfois absent — c'est son employé qui tient la boutique seul. Le soir, présent ou non, il doit savoir ce qui s'est passé.

---

## Forces Motrices (Q4)

**Espoir :** Le soir, ouvrir l'app et voir exactement ce qui a été vendu, par qui, et ce qu'il reste en stock.

**Crainte :** Qu'il y ait un écart dans la caisse et qu'il ne sache pas si c'est son employé ou une erreur — comme avant.

---

## Appareil & Point d'Entrée (Q5 + Q6)

**Appareil :**
- Employé (POS) : Desktop principalement · mobile si pas encore de PC disponible
- Bernard (consultation soir) : Mobile ou desktop — son choix

**Entrée :** L'employé ouvre l'app sur le PC de la boutique en début de journée et se connecte sur sa session. Bernard consulte le soir depuis le même PC ou son téléphone.

---

## Meilleur Résultat (Q7)

**Succès Bernard :**
Le soir il ouvre l'app, voit le CA exact de la journée, les ventes par employé, et le stock restant — en moins de 5 minutes, sans un seul coup de fil à son employé.

**Succès business :**
Usage quotidien prouvé → rétention Standard → O1.2 10 clients payants.

---

## Chemin le Plus Court (Q8)

1. **Dashboard Employé** — L'employé ouvre sa session en début de journée, voit ses tâches du jour
2. **POS Catalogue** — Il cherche et sélectionne les produits à vendre
3. **POS Panier** — Il ajoute les articles, voit le total en temps réel
4. **POS Paiement** — Il encaisse (cash ou mobile money)
5. **POS Reçu** — Confirmation transaction, option reçu client
6. **Stock Liste** — Bernard consulte le soir : CA du jour, niveaux stock restants, ventes par employé ✓

---

## Connexions Trigger Map

**Persona :** Bernard le Boutiquier (P2 Standard)

**Forces motrices adressées :**
- ✅ **Want P1 :** Fermer sa journée en < 5 minutes avec un chiffre fiable
- ✅ **Want P2 :** Voir en temps réel ce qu'il a en stock sans compter physiquement
- ✅ **Want P3 :** Identifier immédiatement qui a vendu quoi si un écart apparaît
- ❌ **Fear N3 :** Peur de se faire voler sans s'en rendre compte

**Objectif business :** O1.2 — 10 clients payants · rétention > 70% · ARR 3–4M FCFA

---

## Étapes du Scénario

| Étape | Dossier | Objet | Action de sortie |
|-------|---------|-------|-----------------|
| 04.1 | `04.1-dashboard-employe/` | L'employé s'identifie et voit ses tâches | Tape "Nouvelle vente" → POS Catalogue |
| 04.2 | `04.2-pos-catalogue/` | Sélection des produits | Produit sélectionné → POS Panier |
| 04.3 | `04.3-pos-panier/` | Composition du panier | Valide → POS Paiement |
| 04.4 | `04.4-pos-paiement/` | Encaissement | Paiement confirmé → POS Reçu |
| 04.5 | `04.5-pos-recu/` | Confirmation + reçu optionnel | Nouvelle vente ou fin → retour catalogue |
| 04.6 | `04.6-stock-liste/` | Bernard consulte le soir — CA + stock + ventes par employé | Fin — certitude acquise ✓ |
