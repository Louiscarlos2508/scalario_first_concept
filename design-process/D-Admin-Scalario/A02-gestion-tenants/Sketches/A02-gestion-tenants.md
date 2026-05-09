---
scenario: "A02"
sketch-type: hi-fi-ascii
platform: flutter-web-desktop
screen-width: 1280px+
font: Inter + Roboto Mono
states: [liste-tenants, detail-tenant, suspension-confirmation]
---

# Sketch Hi-Fi — A02 Gestion Tenants (Admin Scalario)

> Liste et gestion de tous les tenants clients — statut, santé, actions admin.
> Platform : Flutter Web desktop uniquement. Accès équipe Scalario.
> Entry : Dashboard A01 → nav "Tenants".

---

## ÉTAT 1 — Liste Tenants

```
╔══════════════════════════════════════════════════════════════════════════════════╗  1280px
║  ┌────────┐  ┌──────────────────────────────────────────────────────────────┐   ║
║  │ ADMIN  │  │  TENANTS                                      Carlos S.  ⚙️  │   ║  TopBar 56px
║  │ Sidebar│  └──────────────────────────────────────────────────────────────┘   ║
║  │        │                                                                     ║
║  │  📊    │  GESTION TENANTS · 12 actifs                                        ║  PageHeader Inter 20sp 700
║  │  🏢 [●]│  ─────────────────────────────────────────────────────────────────  ║
║  │  👤    │                                                                     ║
║  │  💰    │  ┌───────────────────────────────────────────────────────────────┐  ║
║  │  📡    │  │ 🔍 Rechercher tenant ou intégrateur...    [ + Nouveau tenant ] │  ║  SearchBar + CTA (lien → S17)
║  │        │  └───────────────────────────────────────────────────────────────┘  ║
║  │        │                                                                     ║
║  │        │  [ Tous (12) ] [ ✓ Actifs (11) ] [ ⚠ Trial (1) ] [ ⛔ Suspendus (0) ] [ 💰 Impayés (0) ]  ║  FilterChips statut
║  │        │                                                                     ║
║  │        │  ┌───────────────────────────────────────────────────────────────┐  ║  ← DataTable tenants
║  │        │  │ Nom Tenant          Intégrateur   Template    Statut   MRR    │  ║  en-tête Inter 12sp 600 neutral-600
║  │        │  │ ─────────────────────────────────────────────────────────── │  ║  Roboto Mono pour MRR
║  │        │  │ Boutique Kouamé     Kofi Mensah   retail_fp  ✓ Actif  40k  ›  │  ║  lignes Inter 13sp neutral-800
║  │        │  │ Shop Aminata        Kofi Mensah   retail_fp  ✓ Actif  40k  ›  │  ║  › = clic → détail
║  │        │  │ Épicerie Centrale   Kofi Mensah   retail_fp  ✓ Actif  40k  ›  │  ║
║  │        │  │ Marché du Plateau   Kofi Mensah   retail_fp  ✓ Actif  60k  ›  │  ║
║  │        │  │ Super Yidaba        Kofi Mensah   retail_fp  ⚠ Trial  —    ›  │  ║  Trial : badge warning-100 warning-700
║  │        │  │ [... 7 autres tenants ...]                                     │  ║
║  │        │  └───────────────────────────────────────────────────────────────┘  ║
║  │        │                                                                     ║
║  │        │  Pagination : 1-10 de 12 tenants · [←] [1] [2] [→]                 ║  Inter 12sp · paginator
║  └────────┘                                                                     ║
╚══════════════════════════════════════════════════════════════════════════════════╝

DataTable :
  colonnes fixes : Nom / Intégrateur / Template / Statut / MRR / ›
  tri par colonne (clic en-tête → ↑↓)
  hover ligne : bg primary-50
  clic ligne : → ÉTAT 2 Détail Tenant

StatusBadge :
  ✓ Actif   : bg success-100 · color success-700 · Inter 11sp 500
  ⚠ Trial   : bg warning-100 · color warning-700
  ⛔ Suspendu: bg danger-100  · color danger-700
  💰 Impayé : bg orange-100  · color orange-700

MRR : Roboto Mono 13sp · k = millier (40k = 40 000 FCFA)
```

---

## ÉTAT 2 — Détail Tenant (Boutique Kouamé)

```
╔══════════════════════════════════════════════════════════════════════════════════╗  1280px
║  ┌────────┐  ┌──────────────────────────────────────────────────────────────┐   ║
║  │ ADMIN  │  │  TENANTS › BOUTIQUE KOUAMÉ                    Carlos S.  ⚙️  │   ║  Breadcrumb
║  │        │  └──────────────────────────────────────────────────────────────┘   ║
║  │  🏢 [●]│                                                                     ║
║  │        │  ┌────────────────────────────────────────────────────────────────┐ ║  ← PageHeader tenant
║  │        │  │  🏢 BOUTIQUE KOUAMÉ                 ✓ Actif depuis 09/05/2026  │ ║  bg neutral-50 · padding 20px
║  │        │  │  Cocody, Abidjan · retail_fresh_produce.json · Kofi Mensah     │ ║  Inter 20sp 700 + badges
║  │        │  └────────────────────────────────────────────────────────────────┘ ║
║  │        │                                                                     ║
║  │        │  ┌─────────────────────┐  ┌─────────────────┐  ┌────────────────┐  ║  ← 3 KPICards santé
║  │        │  │ Dernière sync Drift │  │  FCM 7 derniers │  │  MRR           │  ║
║  │        │  │ Il y a 12 min ✓    │  │  jours : 98,2%  │  │  40 000 FCFA   │  ║  Roboto Mono 20sp 700
║  │        │  └─────────────────────┘  └─────────────────┘  └────────────────┘  ║  bg success-50 / neutral-50
║  │        │                                                                     ║
║  │        │  ┌──────────────────────────────────┐  ┌──────────────────────────┐ ║  2-col
║  │        │  │  INFORMATIONS ENTREPRISE          │  │  UTILISATEURS (3)        │ ║
║  │        │  │  ────────────────────────────── │  │  ─────────────────────── │ ║
║  │        │  │  Nom       Boutique Kouamé       │  │  BK Blandine Kouamé OWNER│ ║  UserList
║  │        │  │  Adresse   Cocody, Abidjan        │  │     Dernière conn.: 09/05│ ║  Inter 13sp
║  │        │  │  Secteur   Épicerie / Fresh prod. │  │     07h58                │ ║
║  │        │  │  Template  retail_fresh_produce   │  │  KM Kofi Mensah   COMM.  │ ║
║  │        │  │  Monnaie   FCFA                   │  │     Dernière conn.: 09/05│ ║
║  │        │  │  RCCM      CI-ABJ-2025-B-1234     │  │     08h15                │ ║
║  │        │  │  KYC       ✓ Vérifié par Kofi     │  │  IC Ibrahim Coulibaly MGR│ ║
║  │        │  │  Intégrat. Kofi Mensah (+225...)  │  │     Dernière conn.: 09/05│ ║
║  │        │  └──────────────────────────────────┘  │     09h00                │ ║
║  │        │                                        └──────────────────────────┘ ║
║  │        │  ─────────────────────────────────────────────────────────────────  ║  Separator
║  │        │  ACTIONS ADMIN                                                       ║
║  │        │  [  Accès lecture  ]  [  Contacter Kofi  ]  [  ⛔ Suspendre  ]      ║
║  │        │  bg neutral-100      bg neutral-100         bg danger-50 danger-700 ║
║  │        │  Inter 13sp 500      WhatsApp deeplink       ConfirmationDialog      ║
║  └────────┘                                                                     ║
╚══════════════════════════════════════════════════════════════════════════════════╝

Actions admin :
  "Accès lecture" : mode support — admin voit les données du tenant (lecture seule)
  "Contacter Kofi" : wa.me/{tel_kofi} avec contexte tenant
  "Suspendre" : destructif → ConfirmationDialog obligatoire (ÉTAT 3)

RCCM : Roboto Mono 13sp (identifiant)
Dates : Roboto Mono 12sp (timestamps)
```

---

## ÉTAT 3 — Dialog Confirmation Suspension

```
╔══════════════════════════════════════════════════════════════════════════════════╗  1280px
║  [Détail Tenant — grisé en arrière]                                             ║  overlay 40% opaque
║                                                                                 ║
║         ┌─────────────────────────────────────────────────────────┐             ║
║         │  ⛔ Suspendre BOUTIQUE KOUAMÉ ?                         │             ║  ConfirmationDialog
║         │  ─────────────────────────────────────────────────────  │             ║  bg white · radius-lg · shadow-xl
║         │                                                          │             ║  max-width 480px · centré
║         │  Cette action désactivera immédiatement l'accès de      │             ║
║         │  tous les utilisateurs du tenant.                       │             ║  Inter 14sp color-neutral-600
║         │                                                          │             ║
║         │  • 3 utilisateurs perdront l'accès                      │             ║
║         │  • Les données sont préservées                          │             ║
║         │  • Réactivation possible via "Réactiver"                │             ║
║         │                                                          │             ║
║         │  Raison de suspension (obligatoire) :                    │             ║
║         │  ┌─────────────────────────────────────────────────┐   │             ║
║         │  │ Impayé depuis 35 jours — Relance N°3 envoyée  │   │             ║  TextInput raison · Inter 13sp
║         │  └─────────────────────────────────────────────────┘   │             ║
║         │                                                          │             ║
║         │  ┌──────────────────┐  ┌────────────────────────────┐  │             ║
║         │  │    Annuler       │  │  ⛔ Confirmer la suspension │  │             ║
║         │  └──────────────────┘  └────────────────────────────┘  │             ║
║         │  bg white border neu  bg danger-600 color-white         │             ║
║         │  Inter 14sp 500       Inter 14sp 600                    │             ║
║         └─────────────────────────────────────────────────────────┘             ║
╚══════════════════════════════════════════════════════════════════════════════════╝

Champ "Raison" obligatoire avant que "Confirmer" devienne actif
→ traçabilité audit trail (qui a suspendu + pourquoi)
→ Drift backend enregistre suspension_reason + suspended_by + suspended_at
→ tous les JWT du tenant invalidés
→ push FCM Kofi : "⚠️ Tenant Boutique Kouamé suspendu — Carlos S."
```

---

## Annotations — Gestion Tenants

### Layout DataTable

```
Colonnes :
  Nom Tenant       : Inter 13sp 500 neutral-800 · max-w 200px ellipsis
  Intégrateur      : Inter 13sp 400 neutral-600
  Template         : Inter 13sp 400 neutral-500 italic
  Statut           : StatusBadge (badge chip)
  MRR              : Roboto Mono 13sp 700 neutral-900 · right-align
  ›                : chevron Inter 16sp neutral-400

Tri par défaut : Statut (actifs en haut) puis date activation
```

### Actions Admin Disponibles

| Action | Conditions | Effet |
|--------|-----------|-------|
| Accès lecture | Toujours | Lecture seule données tenant pour support |
| Contacter Kofi | Toujours | WhatsApp deeplink vers intégrateur |
| Suspendre | Statut ≠ Suspendu | Invalidation JWTs + AlertBanner |
| Réactiver | Statut = Suspendu | Réactive l'accès + notif Kofi |
| Transférer | Toujours | Reassigne vers autre intégrateur |
