# 02: Vivien encaisse une vente

**Project:** Scalario Retail Phase 1
**Created:** 2026-04-06
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Encaisser une vente détail complète, imprimer la facture, en moins de 30 secondes — sans hésitation, sans faire attendre le client. L'acte de cœur du POS.

---

## Business Goal (Q2)

**Goal:** RETENTION — Abandon de l'ancien outil en moins de 2 semaines
**Objective:** Si le POS Scalario est plus rapide et plus pro que le cahier, Vivien ne reviendra jamais en arrière. Sert aussi THE ENGINE — Vivien est le testeur secondaire prêt à adopter immédiatement.

---

## User & Situation (Q3)

**Persona:** Vivien (SECONDARY) — acteur réel : Aïcha, sa vendeuse
**Situation:** Aïcha, vendeuse de Vivien, dans la boutique cosmétiques de Ouagadougou, 14h30 mardi après-midi. Une cliente arrive avec une crème hydratante et un savon. Vivien n'est pas là (rendez-vous extérieur). Aïcha tient le téléphone pro connecté à l'imprimante thermique Bluetooth posée sur le comptoir. La cliente a déjà l'argent en main — billet de 5000 F.

---

## Driving Forces (Q4)

**Hope:** Encaisser vite, donner une vraie facture imprimée, ne pas faire attendre la cliente, ne pas se tromper de prix.

**Worry:** Bloquer sur la recherche d'un produit, se tromper de quantité ou de mode de paiement, que l'imprimante ne réponde pas et passer pour incompétente devant la cliente.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Tablette ou téléphone Android partagé sur le comptoir, profil "Aïcha — Vendeuse" actif. Imprimante thermique Bluetooth déjà appairée.
**Entry:** Aïcha est déjà sur le POS (écran de vente ouvert en permanence). La cliente pose les 2 produits sur le comptoir. Aïcha tape directement dans la recherche produit.

---

## Best Outcome (Q7)

**User Success:**
En moins de 30 secondes : 2 produits ajoutés, mode Cash sélectionné, monnaie calculée auto (5000 − 3500 = 1500 F à rendre), facture imprimée et tendue à la cliente avec la monnaie. Vente enregistrée, stock décrémenté, sync en arrière-plan.

**Business Success:**
Vente complète tracée (produits, prix, vendeuse, mode paiement, horodatage). Facture imprimée = preuve de pro vs cahier. Adoption quotidienne du POS confirmée. Différenciation immédiate vs Gescom (offline + impression thermique).

---

## Shortest Path (Q8)

1. **POS Vente détail (7)** — Recherche "crème" → ajout panier. Recherche "savon" → ajout panier. Total 3500 F affiché.
2. **Sélection mode de paiement (9)** — Tape "Encaisser" → modal Cash (default) / Wave / Orange Money / Crédit. Tape Cash, saisit 5000 → monnaie 1500 F affichée.
3. **Confirmation vente + facture (11)** — Récap + bouton "Imprimer & terminer" → impression thermique Bluetooth → toast "Vente enregistrée" → retour POS. ✓

---

## Trigger Map Connections

**Persona:** Vivien (SECONDARY) — acteur : sa vendeuse Aïcha

**Driving Forces Addressed:**
- ✅ **Want:** Professionnalisation (factures imprimées) + supervision bienveillante
- ❌ **Fear:** Cahier insuffisant + pas de facture = pas pro

**Business Goal:** RETENTION (Priorité #3) — abandon ancien outil <2 semaines

---

## Scenario Steps

| Step | Folder | Purpose | Exit Action |
|------|--------|---------|-------------|
| 02.1 | `02.1-pos-vente-detail/` | Construire le panier (recherche + ajout produits) | Tape "Encaisser" → modal paiement |
| 02.2 | `02.2-selection-paiement/` | Choisir mode + saisir montant + voir monnaie | Tape "Valider" → écran confirmation |
| 02.3 | `02.3-confirmation-facture/` | Récap + impression thermique + clôture vente | Tape "Imprimer & terminer" → retour POS ✓ |

**Note:** La page 10 (Sélection client CRM) est sortie du flow cash standard et sera couverte dans le scénario 07 (CRM/crédit).
