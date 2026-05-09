---
project: scalario
phase: "3"
status: complete
created: 2026-05-09
template: retail_fresh_produce.json
---

# UX Scenarios: Scalario

> Scenario outlines connecting Trigger Map personas to concrete user journeys

**Created:** 2026-05-09
**Author:** Carlos Simporé avec Saga (WDS)
**Method:** Whiteport Design Studio (WDS)
**Architecture:** BDUI Engine — composants + états, pas écrans codés en dur

---

## Scenario Summary

| ID | Scénario | Persona | Steps | Gate 0 | Statut |
|----|----------|---------|-------|--------|--------|
| 01 | [Blandine's Morning Read](01-blandines-morning-read/01-blandines-morning-read.md) | Blandine (OWNER) | 2 | ✅ | ✅ Outlined |
| 02 | [Commercial's Quick Sale](02-commercials-quick-sale/02-commercials-quick-sale.md) | Commercial | 3 | ✅ | ✅ Outlined |
| 03 | [Blandine & Commercial's Caisse Close](03-blandine-commercial-caisse-close/03-blandine-commercial-caisse-close.md) | Blandine × Commercial | 3 | ✅ | ✅ Outlined |
| 04 | [Blandine's Alert Response](04-blandines-alert-response/04-blandines-alert-response.md) | Blandine (OWNER) | 3 | ✅ | ✅ Outlined |
| 05 | [Ibrahim's Delivery Validation](05-ibrahims-delivery-validation/05-ibrahims-delivery-validation.md) | Ibrahim (MANAGER) | 3 | ✅ | ✅ Outlined |
| 06 | [Ibrahim & Blandine's Loss Declaration](06-ibrahim-blandine-loss-declaration/06-ibrahim-blandine-loss-declaration.md) | Ibrahim × Blandine | 3 | ✅ | ✅ Outlined |
| 07 | [Kofi's Client First Launch](07-kofis-client-first-launch/07-kofis-client-first-launch.md) | Kofi (intégrateur) | 2 | ✅ | ✅ Outlined |
| 08 | [Blandine's Offline Day](08-blandines-offline-day/08-blandines-offline-day.md) | Tous rôles | 3 | ✅ | ✅ Outlined |
| 09 | [Blandine's Product Setup](09-blandines-product-setup/09-blandines-product-setup.md) | Blandine (OWNER) | 3 | ✅ | ✅ Outlined |
| 10 | [Blandine's Team Management](10-blandines-team-management/10-blandines-team-management.md) | Blandine (OWNER) | 3 | ✅ | ✅ Outlined |
| 11 | [Blandine's Supplier Setup](11-blandines-supplier-setup/11-blandines-supplier-setup.md) | Blandine (OWNER) | 3 | ✅ | ✅ Outlined |
| 12 | [Blandine's Daily Report](12-blandines-daily-report/12-blandines-daily-report.md) | Blandine (OWNER) | 3 | ✅ | ✅ Outlined |
| 13 | [Blandine's Alert Config](13-blandines-alert-config/13-blandines-alert-config.md) | Blandine (OWNER) | 3 | ✅ | ✅ Outlined |
| 14 | [Commercial's Sale Return](14-commercials-sale-return/14-commercials-sale-return.md) | Commercial | 3 | ✅ | ✅ Outlined |
| 15 | [Commercial's Credit Sale](15-commercials-credit-sale/15-commercials-credit-sale.md) | Commercial | 3 | ✅ | ✅ Outlined |
| 16 | [Blandine's Supplier Order](16-blandines-supplier-order/16-blandines-supplier-order.md) | Blandine (OWNER) | 3 | ✅ | ✅ Outlined |
| 17 | [Kofi's Tenant Deployment](17-kofis-tenant-deployment/17-kofis-tenant-deployment.md) | Kofi (intégrateur) | 3 | ✅ | ✅ Outlined |
| 18 | [Ibrahim's Inventory Count](18-ibrahims-inventory-count/18-ibrahims-inventory-count.md) | Ibrahim (MANAGER) | 3 | ✅ | ✅ Outlined |
| 19 | [Blandine's Stock History](19-blandines-stock-history/19-blandines-stock-history.md) | Blandine (OWNER) | 3 | ✅ | ✅ Outlined |
| 20 | [Blandine's Owner Dashboard](20-blandines-owner-dashboard/20-blandines-owner-dashboard.md) | Blandine (OWNER) | 1 | ✅ | ✅ Outlined |
| 21 | [Commercial's Dashboard](21-commercials-dashboard/21-commercials-dashboard.md) | Commercial | 1 | ✅ | ✅ Outlined |
| 22 | [Ibrahim's Manager Dashboard](22-ibrahims-manager-dashboard/22-ibrahims-manager-dashboard.md) | Ibrahim (MANAGER) | 1 | ✅ | ✅ Outlined |
| 23 | [First Login — Password Change](23-first-login-password-change/23-first-login-password-change.md) | Tous rôles | 1 | ✅ | ✅ Outlined |
| 24 | [PIN & Biometric Setup](24-pin-biometric-setup/24-pin-biometric-setup.md) | Tous rôles | 1 | ✅ | ✅ Outlined |
| 25 | [Profile Settings](25-profile-settings/25-profile-settings.md) | Tous rôles | 2 | ✅ | ✅ Outlined |
| 26 | [Ouverture de Caisse](26-ouverture-caisse/26-ouverture-caisse.md) | Commercial / Blandine | 2 | ✅ | ✅ Outlined |
| 27 | [Ticket de Caisse & Facture PDF](27-ticket-caisse-facture/27-ticket-caisse-facture.md) | Commercial | 2 | ✅ | ✅ Outlined |
| 28 | [Export de Rapport](28-export-rapport/28-export-rapport.md) | Blandine (OWNER) | 1 | ✅ | ✅ Outlined |

**Total : 28 scénarios — 67 steps — Gate 0 : 8 juillet 2026**

---

## Couverture par Persona

| Persona | Scénarios | Rôle |
|---------|-----------|------|
| Blandine (OWNER) | 01, 03, 04, 08, 09, 10, 11, 12, 13, 16, 19, 20, 26, 28 | 14 scénarios — priorité #1 |
| Commercial | 02, 03, 08, 14, 15, 21, 26, 27 | 8 scénarios |
| Ibrahim (MANAGER) | 05, 06, 08, 18, 22 | 5 scénarios |
| Kofi (intégrateur) | 07, 17 | 2 scénarios |
| Tous rôles | 08, 23, 24, 25 | Auth + profil transversal |

---

## Composants BDUI identifiés

Ces composants alimentent le Design System Phase 4 :

| Composant | Scénarios | États documentés |
|-----------|-----------|-----------------|
| `KPICard` | 01, 03, 04, 05, 12, 15, 16, 18, 19, 20, 21, 22 | nominal / alerte / offline / vide |
| `ActionButton` | 02–22 | primaire / secondaire / disabled / loading / destructif |
| `AlertBanner` | 01, 04, 06, 08, 13, 14, 15, 16, 17, 18, 19, 20, 22 | info / ambre / rouge / vert succès / absent |
| `SyncStatusBar` | 01, 02, 03, 05, 07, 08, 20, 21, 22 | synced / offline / syncing |
| `TransactionList` | 02, 03, 06, 12, 14, 15, 19, 21 | en cours / validé / annulé / crédit |
| `FormWidget` | 03, 05, 06, 09, 10, 11 | saisie / erreur / succès |
| `ConfirmationDialog` | 03, 05, 06, 14, 17 | récap / garde-fou destructif |
| `ProductSelector` | 02, 06, 09, 15, 16, 19 | liste / sélectionné / stock insuffisant |
| `QuantityControl` | 02, 05, 06, 15, 16, 18 | +/- / bloqué au max / vrac/unit |
| `ChartWidget` | 12, 20 | line chart CA / bar chart |
| `RankingList` | 12, 20 | top articles / tappable |
| `PeriodSelector` | 12, 19 | jour / semaine / mois / perso |
| `FilterChips` | 12, 14, 18, 19 | multi-select / actif / inactif |
| `Toggle` | 10, 13 | actif / inactif |
| `NumberInput` | 13 | seuil configurable |
| `TimePicker` | 13 | heure envoi alerte |
| `ChipSelector` | 09, 13, 14, 15, 16, 17, 18 | canal / mode paiement / pos_type |
| `AlertConfigList` | 13 | depuis template JSON |
| `AlertPreview` | 13, 15 | texte clair "Tu recevras…" |
| `EmployeeList` | 10 | nom / rôle / statut / dernier login |
| `SupplierList` | 11, 16 | nom / produits / prix |
| `ProductPriceList` | 11, 16 | articles + prix achat + marge |
| `CredentialsCard` | 10, 17 | username + mot de passe temp + WhatsApp share |
| `StatusBadge` | 14, 18, 19 | actif / annulé / crédit / écart stock |
| `TemplateSelector` | 17 | templates disponibles + aperçu |
| `ProgressBar` | 18 | avancement inventaire |
| `OnboardingCard` | 07 | first-run / dismissable |
| `ProfileLoader` | 07 | fetch tenant + rôle + permissions + layout |
| `LoginWidget` | 07 | vide / rempli / erreur |

---

## Architecture Notes

Voir [_architecture-notes.md](_architecture-notes.md) pour les décisions transversales :
- Identité & Auth (username/tel + mot de passe → profil complet)
- Re-auth rapide (PIN / fingerprint / Face ID)
- Multi-device (mobile + Flutter Web PWA)
- POS — deux niveaux : `pos_layout` (business) + `input_type` (produit)
- BDUI Engine — composants, pas écrans codés en dur
- Offline-first (Drift = source de vérité)
- **Backend-Down vs Offline** — distinction UX critique (ErrorState vs SyncStatusBar)
- **FCM Push Notifications** — permission Android 13+, types Gate 0, silence nocturne
- **Template Update Flow** — mise à jour JSON sans interruption, backward compatible
- **Session Caisse** — lifecycle ouverture (S26) → journée → fermeture (S03)
- **Documents commerciaux** — ticket, facture PDF, export rapport (génération offline)

---

## Surfaces Scalario

| Surface | Utilisateur | Scénarios |
|---------|-------------|-----------|
| Mobile Android | Blandine / Ibrahim / Commercial | S01–S28 |
| Flutter Web PWA | Blandine (back-office) + Kofi (intégrateur) | S07, S12, S16, S17, S19, S20, S27.2, S28 |
| Admin Scalario (Flutter Web statique) | Équipe Scalario | Voir [D-Admin-Scalario/](../D-Admin-Scalario/00-admin-scalario.md) |

---

## Phase suivante

Ces outlines alimentent **Phase 4 : Design System** où chaque composant reçoit :
- Tokens de design (couleurs, typographie, espacements)
- Variants par état (nominal, alerte, offline, vide)
- Spécifications d'interaction
- Wireframes / maquettes

---

_Generated with Whiteport Design Studio (WDS) — Carlos Simporé — 2026-05-09_
