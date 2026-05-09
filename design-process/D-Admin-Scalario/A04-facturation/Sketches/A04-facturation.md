---
scenario: "A04"
sketch-type: hi-fi-ascii
platform: flutter-web-desktop
screen-width: 1280px+
font: Inter + Roboto Mono
states: [vue-globale, detail-tenant-facturation, relance]
---

# Sketch Hi-Fi — A04 Facturation (Admin Scalario)

> Suivi MRR global et par tenant — historique paiements, statuts, relances.
> Platform : Flutter Web desktop uniquement. Accès équipe Scalario.
> Entry : Dashboard A01 → nav "Facturation" · ou depuis alerte paiement en retard.

---

## ÉTAT 1 — Vue Globale Facturation

```
╔══════════════════════════════════════════════════════════════════════════════════╗  1280px
║  ┌────────┐  ┌──────────────────────────────────────────────────────────────┐   ║
║  │ ADMIN  │  │  FACTURATION                                  Carlos S.  ⚙️  │   ║
║  │  💰 [●]│  └──────────────────────────────────────────────────────────────┘   ║
║  │        │                                                                     ║
║  │        │  FACTURATION · Période : mai 2026                ▼ Changer période  ║  PageHeader
║  │        │  ─────────────────────────────────────────────────────────────────  ║
║  │        │                                                                     ║
║  │        │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────┐   ║  ← 4 KPICards
║  │        │  │  MRR total   │ │ Paiements en │ │ Impayés >30j │ │ Encaissé │   ║
║  │        │  │ 480 000 FCFA │ │ retard       │ │              │ │ ce mois  │   ║
║  │        │  │ ↑ +80k/M-1   │ │     0        │ │      0       │ │ 480 000  │   ║  Roboto Mono 24sp 700
║  │        │  └──────────────┘ └──────────────┘ └──────────────┘ └──────────┘   ║
║  │        │  bg neutral-50  bg success-50      bg success-50   bg neutral-50   ║
║  │        │  val neutral-900 val success-700   val success-700 val neutral-900 ║
║  │        │                                                                     ║
║  │        │  ┌──────────────────────────────────────────────────────────────┐   ║  ← ChartWidget MRR 12 mois
║  │        │  │  MRR — 12 derniers mois (en FCFA)                            │   ║
║  │        │  │  500k┤                                         ●             │   ║
║  │        │  │  400k┤                          ╭─────────────╯              │   ║  Roboto Mono 11sp axes Y
║  │        │  │  300k┤            ╭─────────────╯                            │   ║
║  │        │  │  200k┤ ╭──────────╯                                          │   ║
║  │        │  │  100k┤─╯                                                    │   ║
║  │        │  │       Juin Jul Aoû Sep Oct Nov Déc Jan Fév Mar Avr Mai       │   ║  Inter 11sp axes X
║  │        │  └──────────────────────────────────────────────────────────────┘   ║
║  │        │                                                                     ║
║  │        │  ┌──────────────────────────────────────────────────────────────┐   ║  ← DataTable tenants facturation
║  │        │  │ Tenant              Plan      Montant    Prochain pmt  Statut │   ║
║  │        │  │ ────────────────────────────────────────────────────────────  │   ║
║  │        │  │ Boutique Kouamé     Standard  40 000    01/06          ✓ OK  ›│   ║  Roboto Mono pour montants
║  │        │  │ Shop Aminata        Standard  40 000    01/06          ✓ OK  ›│   ║
║  │        │  │ Épicerie Centrale   Standard  40 000    01/06          ✓ OK  ›│   ║
║  │        │  │ Marché du Plateau   Premium   60 000    01/06          ✓ OK  ›│   ║
║  │        │  │ [... 8 autres ...]                                             │   ║
║  │        │  └──────────────────────────────────────────────────────────────┘   ║
║  └────────┘                                                                     ║
╚══════════════════════════════════════════════════════════════════════════════════╝

ChartWidget MRR :
  Line chart · color-primary-500 stroke 2px
  Axes Y : Roboto Mono 11sp neutral-400 · valeurs en "k" (400k)
  Axes X : Inter 11sp neutral-400 · mois abrégés
  ● = mois actuel · taille 6px

DataTable facturation :
  Statut : ✓ OK (success) / ⚠ Retard (warning) / ⛔ Impayé (danger)
  Dates prochain pmt : Roboto Mono 13sp
  Montant : Roboto Mono 13sp 700 right-align
```

---

## ÉTAT 2 — Détail Tenant (Onglet Facturation)

```
╔══════════════════════════════════════════════════════════════════════════════════╗  1280px
║  ┌────────┐  ┌──────────────────────────────────────────────────────────────┐   ║
║  │ ADMIN  │  │  FACTURATION › BOUTIQUE KOUAMÉ               Carlos S.  ⚙️  │   ║
║  │  💰 [●]│  └──────────────────────────────────────────────────────────────┘   ║
║  │        │                                                                     ║
║  │        │  ┌──────────────────────┐  ┌─────────────────────────────────────┐  ║  2-col
║  │        │  │  PLAN ACTUEL         │  │  HISTORIQUE PAIEMENTS (6 derniers)   │  ║
║  │        │  │  ─────────────────── │  │  ─────────────────────────────────── │  ║
║  │        │  │  Plan : Standard     │  │  01/05/2026  40 000 FCFA  ✓ Payé    │  ║
║  │        │  │  Montant : 40 000    │  │  01/04/2026  40 000 FCFA  ✓ Payé    │  ║  Roboto Mono montants + dates
║  │        │  │  FCFA/mois           │  │  01/03/2026  40 000 FCFA  ✓ Payé    │  ║
║  │        │  │  Roboto Mono 24sp    │  │  01/02/2026  40 000 FCFA  ✓ Payé    │  ║
║  │        │  │                      │  │  01/01/2026  40 000 FCFA  ✓ Payé    │  ║
║  │        │  │  Prochain pmt :      │  │  01/12/2025  40 000 FCFA  ✓ Payé    │  ║
║  │        │  │  01/06/2026          │  │  ─────────────────────────────────── │  ║
║  │        │  │  Roboto Mono 14sp    │  │  Total encaissé : 240 000 FCFA       │  ║  Roboto Mono 18sp 700
║  │        │  │  ─────────────────── │  │  Part Kofi (60%) : 144 000 FCFA      │  ║
║  │        │  │  Statut : ✓ À jour  │  │  Part Scalario (40%) : 96 000 FCFA   │  ║
║  │        │  │  Intégrateur : Kofi  │  └─────────────────────────────────────┘  ║
║  │        │  └──────────────────────┘                                           ║
║  │        │                                                                     ║
║  │        │  ACTIONS : [  Changer de plan  ]  [  Envoyer relance  ] (grisé - à jour)  ║
║  └────────┘                                                                     ║
╚══════════════════════════════════════════════════════════════════════════════════╝

Historique paiements :
  date : Roboto Mono 13sp · montant : Roboto Mono 13sp 700 · statut badge
  StatusBadge : ✓ Payé (success) / ⚠ En retard (warning) / ⛔ Impayé (danger)

Part Kofi / Part Scalario :
  calcul : montant × 60% et × 40%
  Roboto Mono 14sp (informations de split)
  visible uniquement admin → pas exposé aux intégrateurs directement
```

---

## ÉTAT 3 — Relance Manuelle (Tenant Impayé)

```
╔══════════════════════════════════════════════════════════════════════════════════╗  1280px
║  ┌────────┐                                                                     ║
║  │ ADMIN  │  ┌────────────────────────────────────────────────────────────────┐ ║
║  │  💰 [●]│  │ ⛔ ALERTE PAIEMENT — Super Yidaba — 35 jours de retard         │ ║  AlertBanner rouge
║  │        │  │    Montant dû : 40 000 FCFA · Relance N°3 non répondue         │ ║  bg danger-100 border-l danger-500
║  │        │  │    [  Envoyer nouvelle relance  ]  [  Suspendre le tenant  ]    │ ║
║  │        │  └────────────────────────────────────────────────────────────────┘ ║
║  │        │                                                                     ║
║  │        │  [Détail tenant Super Yidaba ...]                                   ║
║  │        │                                                                     ║
║  │        │  ┌────────────────────────────────────────────────────────────────┐ ║  ← Dialog/Panel relance
║  │        │  │  ENVOYER RELANCE                                                │ ║  bg neutral-50 · radius-md · padding 20px
║  │        │  │  ────────────────────────────────────────────────────────────  │ ║
║  │        │  │  Canal :  [▓ Push FCM + SMS ▓]  [ Email ]                     │ ║  ChipSelector canal
║  │        │  │                                                                 │ ║
║  │        │  │  Message :                                                      │ ║
║  │        │  │  ┌───────────────────────────────────────────────────────────┐  │ ║  TextInput message
║  │        │  │  │ Objet : Rappel paiement Scalario — Super Yidaba           │  │ ║
║  │        │  │  │ Votre abonnement Scalario est en retard de 35 jours...    │  │ ║
║  │        │  │  └───────────────────────────────────────────────────────────┘  │ ║
║  │        │  │                                                                 │ ║
║  │        │  │  Destinataire : Blandine Kouamé (OWNER) · +225 07 12 34 56    │ ║
║  │        │  │                                                                 │ ║
║  │        │  │  [████████████████████ Envoyer la relance ██████████████████] │ ║  bg warning-500 · Inter 14sp 600 white
║  │        │  └────────────────────────────────────────────────────────────────┘ ║
║  └────────┘                                                                     ║
╚══════════════════════════════════════════════════════════════════════════════════╝

Relances automatiques (configurable) :
  J+7  : relance automatique #1 (push FCM)
  J+15 : relance automatique #2 (push FCM + SMS)
  J+30 : relance automatique #3 + alerte A01 admin
  J+45 : suspension automatique (configurable OFF par défaut → manuelle)

Relance manuelle : Carlos peut envoyer à tout moment + modifier le message
```

---

## Annotations — Facturation

### Plans Tarifaires Gate 0

| Plan | Cible | Montant/mois |
|------|-------|--------------|
| PME Standard | Boutique mono-point retail | 40 000–60 000 FCFA |
| PME Premium | Multi-points / multi-dept | 150 000–200 000 FCFA |

### Modèle Split MRR

```
MRR tenant = X FCFA
  Part Kofi (intégrateur) = X × 60%
  Part Scalario = X × 40%
→ Scalario verse Kofi en fin de mois (virement ou wave)
→ Affiché dans détail tenant et détail intégrateur
```

### Statuts Paiement

```
✓ À jour     : prochain paiement dans le futur
⚠ En retard  : paiement > J+7 non reçu → relance #1 auto
⛔ Impayé    : paiement > J+30 → alerte A01 + relance #3
💀 Suspendu  : accès révoqué (via A02 suspension)
```
