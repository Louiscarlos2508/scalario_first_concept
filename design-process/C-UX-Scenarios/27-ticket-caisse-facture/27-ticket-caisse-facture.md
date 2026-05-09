---
project: scalario
scenario: "27"
slug: 27-ticket-caisse-facture
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 27: Ticket de Caisse & Facture PDF

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Après confirmation d'une vente (S02 ou S15), le Commercial génère et partage un ticket de caisse ou une facture PDF — via WhatsApp, SMS, ou impression Bluetooth. Deux sous-cas : ticket simple (vente cash) et facture formelle (vente à crédit ou client pro).

---

## Business Goal (Q2)

**Goal:** O1.1 — Usage terrain + confiance client dans l'outil
**Objective:** O2.1 — Template validé : reçu = preuve que Scalario est un vrai outil pro, pas juste un cahier numérique

---

## User & Situation (Q3)

**Persona:** Le Commercial (rôle COMMERCIAL)
**Situation:** Vente confirmée, client encore devant lui. Le client demande "tu peux m'envoyer ça ?" ou Blandine a configuré l'envoi automatique.

---

## Driving Forces (Q4)

**Hope:** Envoyer le reçu rapidement sans quitter le flow — impression professionnelle auprès du client.

**Worry:** L'app n'envoie pas le bon format / l'impression Bluetooth plante — gêne devant le client.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android — juste après l'écran de confirmation S02.3 ou S15.3
**Entry:** Écran de confirmation vente → `ActionButton` secondaire "Partager le ticket" visible immédiatement.

---

## Best Outcome (Q7)

**User Success:**
Reçu envoyé via WhatsApp ou imprimé en < 10 sec — client satisfait, transaction traçée.

**Business Success:**
Ticket numérique = archive automatique dans l'historique des transactions + branding Scalario/tenant sur chaque reçu.

---

## Shortest Path (Q8)

1. **Écran post-vente** — `BottomSheet` ou `ActionButton` "Partager le ticket" — tap
2. **Choix du canal** — `ChipSelector` : WhatsApp / SMS / Impression Bluetooth / Ignorer
3. **Envoi/Impression** — Ticket ou PDF généré et partagé → confirmation ✓

---

## Ticket vs Facture

| Document | Déclencheur | Format | Destinataire |
|----------|-------------|--------|-------------|
| Ticket de caisse | Toute vente cash (S02) | Texte simple ou mini PDF | Client (WhatsApp) |
| Facture PDF | Vente à crédit (S15) ou demande client | PDF formel avec en-tête tenant | Client (WhatsApp / email) |

---

## Trigger Map Connections

**Persona:** Commercial

**Driving Forces Addressed:**
- ✅ **Want:** Outil pro perçu comme sérieux — reçu = preuve
- ❌ **Fear:** Client insatisfait sans preuve d'achat

**Business Goal:** O1.1 + O2.1

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 27.1 | `27.1-ticket-caisse/` | Ticket de caisse simple après vente cash | Envoyé via WhatsApp / SMS / Bluetooth |
| 27.2 | `27.2-facture-pdf/` | Facture PDF formelle après vente à crédit | PDF généré et partagé |
