---
design_intent: S
design_status: not-started
---

# 01 : Blandine Ferme Sa Caisse à Distance

**Projet :** Scalario
**Créé :** 2026-03-31
**Méthode :** Whiteport Design Studio (WDS) — Phase 3 Scenarios

---

## Transaction (Q1)

**Ce que ce scénario couvre :**
Blandine est à l'étranger. Sa boutique a fini sa journée. Elle doit valider depuis son téléphone que la caisse est bien clôturée — avec la preuve de qui a fait quoi à chaque étape.

---

## Objectif Business (Q2)

**Objectif :** O1 — Générer un revenu récurrent viable
**SMART :** O1.1 — Signer et encaisser Blandine avant mi-avril 2026 · Gate 1 ARR 400K FCFA
**Rôle :** Feature décisive de la démo → signature contrat

---

## Utilisateur & Situation (Q3)

**Persona :** Blandine la Boutiquière (Priorité 1 — Premium)
**Situation :** Blandine est à l'étranger, dans son appartement. Sa boutique de produits frais à Ouagadougou vient de fermer. Elle ne peut pas se déplacer — son téléphone est son seul lien avec la réalité de son commerce.

---

## Forces Motrices (Q4)

**Espoir :** Voir la caisse propre, signée, sans écart — et fermer la journée en 3 minutes sans appeler son gestionnaire.

**Crainte :** Que les chiffres ne tombent pas, qu'un employé ait fait une erreur ou pire, et qu'elle n'ait aucun moyen de savoir qui.

---

## Appareil & Point d'Entrée (Q5 + Q6)

**Appareil :** Mobile (téléphone)
**Entrée :** Elle reçoit une notification (WhatsApp ou push app selon sa configuration) : "Caisse du jour en attente de votre validation." Elle ouvre l'app → directement sur l'étape de sign-off propriétaire.

---

## Meilleur Résultat (Q7)

**Succès Blandine :**
Elle a signé la caisse en 3 minutes depuis son téléphone. Elle voit le récapitulatif signé avec les noms de chaque employé impliqué. Elle ferme l'app et passe à autre chose.

**Succès business :**
Feature sign-off remote prouvée en conditions réelles → argument #1 de la démo → signature contrat.

---

## Chemin le Plus Court (Q8)

Chemin linéaire — 3 acteurs en séquence, 4 étapes.

1. **Arrêt de caisse — Étape 1** — Le caissier compte sa caisse et soumet le récapitulatif de fin de journée
2. **Arrêt de caisse — Étape 2** — Le gestionnaire vérifie et valide les chiffres soumis par le caissier
3. **Arrêt de caisse — Étape 3** — Blandine reçoit la notification, ouvre l'app, lit le récap 3 niveaux et signe à distance
4. **Historique sessions de caisse** — La session est archivée avec les 3 signatures, horodatée, accessible en audit ✓

---

## Connexions Trigger Map

**Persona :** Blandine la Boutiquière (P1 Premium)

**Forces motrices adressées :**
- ✅ **Want P2 :** Avoir la preuve de qui a fait quoi, dans quelle phase
- ✅ **Want P4 :** Clôturer la caisse avec son sign-off depuis n'importe où
- ❌ **Fear N4 :** Frustration d'une réconciliation caisse qui finit en conflit

**Objectif business :** O1.1 — Gate 1 · Blandine signature · ARR 400K FCFA

---

## Étapes du Scénario

| Étape | Dossier | Objet | Action de sortie |
|-------|---------|-------|-----------------|
| 01.1 | `01.1-arret-caisse-etape-1/` | Le caissier soumet la caisse | Soumet → notifie le gestionnaire |
| 01.2 | `01.2-arret-caisse-etape-2/` | Le gestionnaire valide | Valide → notifie Blandine |
| 01.3 | `01.3-arret-caisse-etape-3/` | Blandine signe à distance | Signe → session clôturée |
| 01.4 | `01.4-historique-sessions/` | Archive horodatée avec 3 signatures | Fin — succès ✓ |
