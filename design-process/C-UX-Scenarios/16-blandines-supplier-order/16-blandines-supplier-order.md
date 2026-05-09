---
project: scalario
scenario: "16"
slug: 16-blandines-supplier-order
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 16: Blandine's Supplier Order

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Blandine passe une commande fournisseur depuis l'app — articles, quantités, fournisseur sélectionné — commande envoyée et tracée dans le système.

---

## Business Goal (Q2)

**Goal:** O1.1 — Commandes tracées = stock anticipé = pas de rupture surprise
**Objective:** O2.2 — Commandes hors système (WhatsApp, mémo) = stocks imprévisibles → churn

---

## User & Situation (Q3)

**Persona:** Blandine (OWNER — priorité #1)
**Situation:** Chez elle ou au magasin. Voit alerte stock critique ou anticipe une rupture → initie commande fournisseur.

---

## Driving Forces (Q4)

**Hope:** Commander vite le bon article au bon fournisseur, savoir quand ça arrive.

**Worry:** Commander les mauvaises quantités ou chez le mauvais fournisseur — gaspillage ou rupture.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android OU Flutter Web PWA
**Entry:** Dashboard OWNER → section "Commandes" ou depuis alerte stock critique → ActionButton "Commander".

---

## Best Outcome (Q7)

**User Success:**
Commande envoyée, fournisseur notifié, commande visible en attente de réception liée à S05 Ibrahim.

**Business Success:**
Pipeline commande→réception tracé → stock prévisible → O1.1.

---

## Shortest Path (Q8)

1. **Sélection Fournisseur** — liste fournisseurs depuis catalogue S11, sélection + articles associés
2. **Saisie Commande** — articles du catalogue fournisseur + quantités souhaitées + note optionnelle
3. **Confirmation Commande** — récap commande créée, Ibrahim notifié (attente réception S05), statut "En attente"

---

## Trigger Map Connections

**Persona:** Blandine (OWNER — priorité #1)

**Driving Forces Addressed:**
- ✅ **Want:** "Commander vite le bon article au bon fournisseur"
- ❌ **Fear:** "Mauvaises quantités / mauvais fournisseur" — résolu par catalogue fournisseur + articles pré-associés + aperçu prix achat

**Business Goal:** O1.1 — Pipeline commande→réception tracé dans le système (lié à S05)

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 16.1 | `16.1-selection-fournisseur/` | Sélection fournisseur depuis catalogue | Tap sur fournisseur |
| 16.2 | `16.2-saisie-commande/` | Articles + quantités + note | Tap "Passer la commande" |
| 16.3 | `16.3-confirmation-commande/` | Commande créée, Ibrahim notifié, statut "En attente" | Commande enregistrée ✓ |

## Liens Scénarios

- **S11** (Blandine's Supplier Setup) — catalogue fournisseurs source pour 16.1
- **S05** (Ibrahim's Delivery Validation) — réception de cette commande par Ibrahim
