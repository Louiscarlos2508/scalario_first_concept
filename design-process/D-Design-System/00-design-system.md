---
project: scalario
phase: "4"
slug: design-system
status: in-progress
created: 2026-05-09
---

# Design System: Scalario

**Method:** Whiteport Design Studio (WDS) — Phase 4
**Architecture:** BDUI Engine — composants rendus depuis JSON
**Font:** Inter (toutes surfaces)
**Plateforme primaire:** Mobile Android + Flutter Web PWA

> Ce design system est **template-agnostic** : les composants, tokens et règles UX
> s'appliquent à tous les templates (retail_fresh_produce.json et futurs).
> Seul le contenu JSON change d'un template à l'autre.

---

## Structure

```
D-Design-System/
  tokens/
    colors.md         ← Palette + tokens sémantiques
    typography.md     ← Inter — échelle typographique
    spacing.md        ← Grille 4px — espacements + layout
    icons.md          ← Bibliothèque Material Icons + tokens taille + mapping sémantique
  ux-rules/
    principles.md     ← 10 règles UX fondamentales (P1–P10)
    patterns.md       ← 10 patterns d'interaction (flows, confirmations, offline…)
    layout.md         ← Navigation, grilles mobile + web + admin
  conventions/
    ascii-sketch.md   ← Conventions complètes pour tous les sketches ASCII hi-fi
    surfaces.md       ← Variants composants par surface (mobile / web / admin)
  components/
    01-feedback.md        ← AlertBanner, StatusBadge, SyncStatusBar, ProgressBar, NotificationBadge, TypeBadge
    02-data-display.md    ← KPICard, TransactionList, RankingList, ChartWidget, InfoCard, DateSeparator, MouvementItem, StockListItem, OperationItem, ContextCard, ContentPreview, DataTable, StatusTable, LogItem
    03-inputs.md          ← TextInput, NumberInput, QuantityControl, TimePicker, DatePicker, Toggle, FormWidget, ExpandableSection
    04-selection.md       ← ProductGrid, ChipSelector, FilterChips, PeriodSelector, ProductSelector, CartSummary, ChoiceCard, PaymentMethodSelector, BluetoothDeviceSelector
    05-actions.md         ← ActionButton, ConfirmationDialog
    06-lists.md           ← EmployeeList, SupplierList, ProductPriceList, AlertConfigList
    07-specialized.md     ← PaymentConfirm, AlertPreview, CredentialsCard, OnboardingCard, EmptyState, LoginWidget, TemplateSelector, AvatarCard, POSPreview
    08-navigation-layout.md ← AppBar, TopBar, BottomNav, SearchBar, BottomSheet, MiniTopBar, Breadcrumb
    09-loading-states.md  ← Skeleton, LoadingSpinner, ErrorState, PasswordStrengthBar, PINInput, ImageUploader, SplashScreen, DriftLoader, ProfileLoader
    10-documents-session.md ← ReceiptPreview, CaisseSessionCard, CreditTracker, TicketPreview, InvoicePreview
  composites/
    01-dashboard-owner.md      ← Dashboard OWNER complet (mobile + web 3col) — S01, S20
    02-dashboard-commercial.md ← Dashboard COMMERCIAL (mobile) — S02, S21
    03-dashboard-manager.md    ← Dashboard MANAGER (mobile) — S05, S06, S22
    04-pos-flow.md             ← Flow POS card grid + crédit — S02, S15
    05-admin-dashboard.md      ← Admin Scalario — A01 à A05
    06-forms.md                ← Formulaires produit, employé, alerte, rapport — S09, S10, S12, S13
    07-auth-onboarding.md      ← Login, MDP forcé, PIN setup, profil — S07, S23, S24, S25
    08-stock-management.md     ← Livraison, perte, inventaire, historique — S05, S06, S18, S19
    09-session-documents.md    ← Caisse ouverte/fermée, ticket, facture, export — S03, S26, S27, S28
```

---

## Index Composants Atomiques (73)

| Composant | Fichier | Scénarios |
|-----------|---------|-----------|
| `AlertBanner` | 01-feedback | 01,04,06,08,13,14,15,16,17,18,19,20,22,26,28 |
| `StatusBadge` | 01-feedback | 14,18,19 |
| `SyncStatusBar` | 01-feedback | 01,02,03,05,07,08,20,21,22,26 |
| `ProgressBar` | 01-feedback | 18,27 |
| `NotificationBadge` | 01-feedback | 01,04,10,20 |
| `TypeBadge` | 01-feedback | 14,18,19,A05 |
| `KPICard` | 02-data-display | 01,03,04,05,12,15,16,18,19,20,21,22,26 |
| `TransactionList` | 02-data-display | 02,03,06,12,14,15,19,21 |
| `RankingList` | 02-data-display | 12,20 |
| `ChartWidget` | 02-data-display | 12,20 |
| `InfoCard` | 02-data-display | 03,05,06,12,14,18,19,20,22,26 |
| `DateSeparator` | 02-data-display | 03,14,18,19 |
| `MouvementItem` | 02-data-display | 14,18,19 |
| `StockListItem` | 02-data-display | 05,06,18,19 |
| `OperationItem` | 02-data-display | 05,06,18,22 |
| `ContextCard` | 02-data-display | 02,14,15,18 |
| `ContentPreview` | 02-data-display | 12,19,28 |
| `DataTable` | 02-data-display | 12,19,20 (web) |
| `StatusTable` | 02-data-display | A01,A05 |
| `LogItem` | 02-data-display | A05 |
| `TextInput` | 03-inputs | 03,05,06,09,10,11,15,16,17,25 |
| `NumberInput` | 03-inputs | 13,18,26 |
| `QuantityControl` | 03-inputs | 02,05,06,15,16,18 |
| `TimePicker` | 03-inputs | 13 |
| `DatePicker` | 03-inputs | 15,16 |
| `Toggle` | 03-inputs | 10,13,24 |
| `FormWidget` | 03-inputs | 09,10,11,13,15,16,17,23,24,25 |
| `ExpandableSection` | 03-inputs | 09,10,17 |
| `ProductGrid` | 04-selection | 02,15 |
| `ChipSelector` | 04-selection | 09,13,14,15,16,17,18,27,28 |
| `FilterChips` | 04-selection | 12,14,18,19,A05 |
| `PeriodSelector` | 04-selection | 12,19 |
| `ProductSelector` | 04-selection | 06,09,16,19 |
| `CartSummary` | 04-selection | 02,15 |
| `ChoiceCard` | 04-selection | 07,24 |
| `PaymentMethodSelector` | 04-selection | 02,15 |
| `BluetoothDeviceSelector` | 04-selection | 27 |
| `ActionButton` | 05-actions | 02–28 |
| `ConfirmationDialog` | 05-actions | 03,05,06,14,17,25 |
| `EmployeeList` | 06-lists | 10 |
| `SupplierList` | 06-lists | 11,16 |
| `ProductPriceList` | 06-lists | 11,16 |
| `AlertConfigList` | 06-lists | 13 |
| `PaymentConfirm` | 07-specialized | 02,15 |
| `AlertPreview` | 07-specialized | 13,15 |
| `CredentialsCard` | 07-specialized | 10,17 |
| `OnboardingCard` | 07-specialized | 07 |
| `EmptyState` | 07-specialized | 07,19 |
| `LoginWidget` | 07-specialized | 07,23 |
| `TemplateSelector` | 07-specialized | 17 |
| `AvatarCard` | 07-specialized | 25 |
| `POSPreview` | 07-specialized | 21 |
| `AppBar` | 08-navigation-layout | tous (mobile) |
| `TopBar` | 08-navigation-layout | tous (web) |
| `BottomNav` | 08-navigation-layout | tous (mobile) |
| `SearchBar` | 08-navigation-layout | 02,09,10,11,14,15,16,18,19 |
| `BottomSheet` | 08-navigation-layout | 02,27,28 |
| `MiniTopBar` | 08-navigation-layout | 20,21,22 |
| `Breadcrumb` | 08-navigation-layout | tous (web — pages secondaires) |
| `Skeleton` | 09-loading-states | 01,07,20,21,22 |
| `LoadingSpinner` | 09-loading-states | 07,17,27,28 |
| `ErrorState` | 09-loading-states | 07,08 |
| `PasswordStrengthBar` | 09-loading-states | 23,25 |
| `PINInput` | 09-loading-states | 24 |
| `ImageUploader` | 09-loading-states | 17 |
| `SplashScreen` | 09-loading-states | 01 |
| `DriftLoader` | 09-loading-states | 01 |
| `ProfileLoader` | 09-loading-states | 07,25 |
| `ReceiptPreview` | 10-documents-session | 27 |
| `CaisseSessionCard` | 10-documents-session | 03,20,26 |
| `CreditTracker` | 10-documents-session | 15,20 |
| `TicketPreview` | 10-documents-session | 27 (alias → ReceiptPreview type=ticket) |
| `InvoicePreview` | 10-documents-session | 27 (alias → ReceiptPreview type=facture) |

---

## Index Composites (9)

| Composite | Fichier | Scénarios couverts |
|-----------|---------|-------------------|
| Dashboard OWNER | 01-dashboard-owner | S01, S20 |
| Dashboard COMMERCIAL | 02-dashboard-commercial | S02, S21 |
| Dashboard MANAGER | 03-dashboard-manager | S05, S06, S22 |
| POS Flow | 04-pos-flow | S02, S15 |
| Admin Dashboard | 05-admin-dashboard | A01–A05 |
| Formulaires | 06-forms | S09, S10, S12, S13 |
| Auth & Onboarding | 07-auth-onboarding | S07, S23, S24, S25 |
| Gestion des Stocks | 08-stock-management | S05, S06, S18, S19 |
| Session & Documents | 09-session-documents | S03, S26, S27, S28 |

---

## Règles UX (10)

| Règle | Principe |
|-------|---------|
| P1 | 30 secondes maximum — état critique visible sans scroll |
| P2 | Une seule ActionButton primaire par vue |
| P3 | Offline transparent — jamais bloquant, jamais alarmiste |
| P4 | Traçabilité mutuelle — protection des deux côtés |
| P5 | Zéro friction sur le chemin critique (vente = 3 taps max) |
| P6 | BDUI — aucun écran codé en dur |
| P7 | Hiérarchie AlertBanner stricte : rouge > ambre > vert > bleu |
| P8 | Personas isolés — chaque rôle voit son périmètre uniquement |
| P9 | Langue française partout — montants FCFA — heures 24h |
| P10 | ConfirmationDialog obligatoire sur toute action irréversible |

---

## Couverture par Scénario

| Scénarios | Composites |
|-----------|------------|
| S01, S20 | Dashboard OWNER |
| S02, S21 | Dashboard COMMERCIAL + POS Flow |
| S03 | Dashboard MANAGER + Session & Documents |
| S04 | Dashboard OWNER (alert response) |
| S05, S06, S18, S19 | Gestion des Stocks |
| S07, S23, S24, S25 | Auth & Onboarding |
| S09, S10, S12, S13 | Formulaires |
| S15 | POS Flow (crédit) |
| S22 | Dashboard MANAGER |
| S26, S27, S28 | Session & Documents |
| A01–A05 | Admin Dashboard |

---

## Extensibilité (nouveaux templates)

- **Composants existants** : réutilisés tels quels — contenu vient du JSON
- **Tokens** : inchangés — ce sont les tokens Scalario (marque, pas métier)
- **Règles UX** : applicables à tous les métiers
- **Nouveaux composants** : ajoutés au Design System si un nouveau template en a besoin
- **Exemple** : template Restaurant → `TableSelector`, `OrderTicket` → ajoutés dans `components/11-restaurant.md`

---

_Generated with Whiteport Design Studio (WDS) — Carlos Simporé — 2026-05-09_
