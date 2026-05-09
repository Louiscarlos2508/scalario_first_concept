---
type: components
group: documents-session
components: [ReceiptPreview, CaisseSessionCard, CreditTracker, TicketPreview, InvoicePreview]
scenarios: [15, 26, 27, 28]
---

# Composants — Documents & Session Caisse

---

## ReceiptPreview

**Rôle :** Aperçu du ticket de caisse ou de la facture PDF dans un `BottomSheet` avant envoi.
**Usage :** S27.1 (ticket cash), S27.2 (facture crédit).

### Props

| Prop | Type | Description |
|------|------|-------------|
| `type` | enum | `ticket` / `facture` |
| `transaction_id` | string | Référence de la transaction |
| `items` | list | Articles + quantités + prix |
| `total` | number | Montant total FCFA |
| `paid` | number | Montant payé (cash) |
| `change` | number | Monnaie rendue (ticket) |
| `credit_amount` | number | Montant crédit restant dû (facture) |
| `due_date` | date | Échéance crédit (facture uniquement) |
| `tenant_name` | string | Nom du tenant (depuis config JSON) |
| `invoice_number` | string | N° facture (facture uniquement — `TMP-XXXX` si offline) |

### Sketches ASCII

```
TICKET DE CAISSE (BottomSheet compact) :
│▓▓ ┌──────────────────────────────────────────┐ ▓│
│▓▓ │  ━━━━━━━━━━━                             │ ▓│
│▓▓ │  Ticket de caisse                        │ ▓│
│▓▓ │  ──────────────────────────────────      │ ▓│
│▓▓ │  ÉPICERIE AMINATA                        │ ▓│
│▓▓ │  09/05/2026  08h43  · Commercial: Kofi   │ ▓│
│▓▓ │  ──────────────────────────────────      │ ▓│
│▓▓ │  Tomates      2,5 kg    3 750 FCFA       │ ▓│
│▓▓ │  Igname       3 kg      4 500 FCFA       │ ▓│
│▓▓ │  Poivrons     500g        800 FCFA       │ ▓│
│▓▓ │  ──────────────────────────────────      │ ▓│
│▓▓ │  TOTAL           9 050 FCFA              │ ▓│
│▓▓ │  Payé cash      10 000 FCFA              │ ▓│
│▓▓ │  Monnaie           950 FCFA              │ ▓│
│▓▓ │  ──────────────────────────────────      │ ▓│
│▓▓ │  [WhatsApp ●]  [SMS ○]  [Imprimer ○]  [─] │ ▓│
│▓▓ │  [████████████ Envoyer ████████████]     │ ▓│
│▓▓ └──────────────────────────────────────────┘ ▓│

FACTURE PDF (BottomSheet medium) :
│▓▓ │  Facture N° 2026-0142                    │ ▓│
│▓▓ │  ──────────────────────────────────      │ ▓│
│▓▓ │  CLIENT : Mme Koné Fatou                 │ ▓│
│▓▓ │           +225 05 11 22 33               │ ▓│
│▓▓ │  ──────────────────────────────────      │ ▓│
│▓▓ │  Tomates cerises  5 kg    7 500 FCFA     │ ▓│
│▓▓ │  Igname           8 kg    8 000 FCFA     │ ▓│
│▓▓ │  ──────────────────────────────────      │ ▓│
│▓▓ │  TOTAL           15 500 FCFA             │ ▓│
│▓▓ │  Acompte reçu     5 000 FCFA             │ ▓│
│▓▓ │  RESTANT DÛ      10 500 FCFA [rouge]     │ ▓│
│▓▓ │  Échéance : 16/05/2026                   │ ▓│
│▓▓ │  ──────────────────────────────────      │ ▓│
│▓▓ │  [WhatsApp ●]  [Email ○]  [Télécharger ○]│ ▓│
│▓▓ │  [████████ Envoyer la facture ██████]    │ ▓│
│▓▓ └──────────────────────────────────────────┘ ▓│

OFFLINE (numéro temporaire) :
│▓▓ │  Facture N° TMP-0023  [⚠ sera confirmé à la sync] │ ▓│
```

### États

| État | Comportement |
|------|-------------|
| `ticket` online | Numéro transaction réel, envoi immédiat |
| `facture` online | Numéro facture séquentiel, PDF généré backend |
| `facture` offline | N° `TMP-XXXX`, PDF généré client (Dart PDF), numéro définitif à la sync |
| Impression Bluetooth | `ProgressBar` inline pendant la recherche imprimante |

---

## CaisseSessionCard

**Rôle :** Carte récapitulative de la session caisse active — fond déclaré, heure, commercial en charge.
**Usage :** S26.2 (confirmation ouverture), S03 (fermeture — comparaison fond initial vs final), Dashboard OWNER.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `status` | enum | `open` / `closed` / `none` |
| `opened_at` | datetime | Heure d'ouverture |
| `opened_by` | string | Prénom du commercial |
| `fond_ouverture` | number | Montant fond déclaré à l'ouverture |
| `fond_cloture` | number | Montant compté à la clôture (S03) |
| `ecart` | number | Écart fond final - attendu (positif/négatif) |
| `closed_at` | datetime | Heure de fermeture (si closed) |

### Sketches ASCII

```
SESSION ACTIVE (Dashboard OWNER) :
╔══════════════════════════════════════════╗
║  🟢 Session ouverte                      ║
║  Depuis 08h15  ·  Kofi                   ║
║  Fond de caisse : 15 000 FCFA            ║
║  CA session : 47 500 FCFA                ║
╚══════════════════════════════════════════╝

SESSION FERMÉE (récap fin de journée) :
╔══════════════════════════════════════════╗
║  ✓ Session clôturée à 19h30              ║
║  Fond ouverture :  15 000 FCFA           ║
║  Fond clôture   :  15 800 FCFA           ║
║  Attendu        :  15 750 FCFA           ║
║  Écart          :    +50 FCFA  [vert]    ║
╚══════════════════════════════════════════╝

ÉCART NÉGATIF (alerte) :
╔══════════════════════════════════════════╗
║  ⚠ Session clôturée à 19h30             ║
║  Écart         :   -1 200 FCFA  [rouge]  ║
║  → Vérifier la caisse                   ║
╚══════════════════════════════════════════╝

AUCUNE SESSION (Commercial — matin) :
╔══════════════════════════════════════════╗
║  ⚠ Aucune session active                ║
║  Ouvrez la caisse avant la première vente║
║  [████ Ouvrir la caisse ████████████]   ║
╚══════════════════════════════════════════╝
```

### États

| État | Couleur | Contexte |
|------|---------|---------|
| `open` | Vert | Session en cours — Dashboard OWNER |
| `closed` sans écart | Vert | Clôture propre |
| `closed` écart positif | Vert | Excédent (rare, pas alarmant) |
| `closed` écart négatif | Rouge | Manque constaté — alerte |
| `none` | Ambre | Pas de session — CTA "Ouvrir la caisse" |

---

## TicketPreview

**Rôle :** Alias de `ReceiptPreview` avec `type = "ticket"` — aperçu du ticket de caisse (vente cash) avant envoi au client.
**Usage :** S27.1 (Ticket caisse — BottomSheet après vente).
**Règle :** Même widget Flutter que `ReceiptPreview`. Le JSON peut référencer `TicketPreview` directement — le renderer résout vers `ReceiptPreview(type: "ticket")`.

```
Alias JSON : TicketPreview → ReceiptPreview(type: "ticket")
Props identiques à ReceiptPreview — voir définition ci-dessus.
Champs non applicables au ticket : invoice_number, credit_amount, due_date (ignorés).
```

---

## InvoicePreview

**Rôle :** Alias de `ReceiptPreview` avec `type = "facture"` — aperçu de la facture PDF (vente à crédit) avant envoi au client.
**Usage :** S27.2 (Facture PDF — BottomSheet après vente crédit).
**Règle :** Même widget Flutter que `ReceiptPreview`. Le JSON peut référencer `InvoicePreview` directement — le renderer résout vers `ReceiptPreview(type: "facture")`.

```
Alias JSON : InvoicePreview → ReceiptPreview(type: "facture")
Props identiques à ReceiptPreview — voir définition ci-dessus.
Champs obligatoires en mode facture : invoice_number, credit_amount, due_date, client_name.
Numérotation offline : TMP-XXXX → numéro définitif à la sync backend.
```

---

## CreditTracker

**Rôle :** Liste des ventes à crédit en cours avec montants restants dus et échéances.
**Usage :** Dashboard OWNER (section "Crédits en cours"), S15 (après confirmation crédit), historique S14.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `credits` | list | Ventes à crédit actives |
| `show_overdue` | bool | Filtre : affiche seulement les crédits en retard |
| `max_items` | number | Nombre max affiché (défaut 5 — voir tout → liste complète) |

### Sketches ASCII

```
CRÉDITS EN COURS (Dashboard OWNER, 3 items) :
┌──────────────────────────────────────────────┐
│ Crédits en cours                  3 actifs   │
├──────────────────────────────────────────────┤
│ Koné Fatou          10 500 FCFA   16/05  ›   │
│ Traoré Ali           7 200 FCFA   20/05  ›   │
│ Diallo Mariame       3 800 FCFA   14/05 [⚠] ›│  ← en retard
├──────────────────────────────────────────────┤
│ Total dû : 21 500 FCFA        [Voir tout →]  │
└──────────────────────────────────────────────┘

CRÉDIT EN RETARD (ligne individuelle) :
│ Diallo Mariame       3 800 FCFA   14/05 [⚠] ›│
  ↑ nom + tel          ↑ montant dû  ↑ échéance ↑ retard badge

AUCUN CRÉDIT :
┌──────────────────────────────────────────────┐
│ Crédits en cours              Aucun crédit   │
└──────────────────────────────────────────────┘
```

### États ligne

| Badge | Couleur | Signification |
|-------|---------|--------------|
| Date future | Gris | Dans les délais |
| `⚠` date passée | Ambre | En retard ≤ 7 jours |
| `!` date passée > 7j | Rouge | En retard critique |
