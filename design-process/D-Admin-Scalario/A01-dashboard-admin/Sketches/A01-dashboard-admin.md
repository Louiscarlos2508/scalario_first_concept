---
scenario: "A01"
sketch-type: hi-fi-ascii
platform: flutter-web-desktop
screen-width: 1280px+
font: Inter + Roboto Mono
states: [sante-ok, alertes-critiques]
---

# Sketch Hi-Fi — A01 Dashboard Admin Scalario

> Vue d'ensemble de la santé de la plateforme — métriques clés, alertes système.
> Platform : Flutter Web desktop uniquement. Accès équipe Scalario.
> Entry : Login admin → page d'accueil par défaut.
> Layout : Sidebar fixe gauche + zone contenu principale.

---

## LAYOUT BASE — Sidebar + Zone Principale

```
╔══════════════════════════════════════════════════════════════════════════════════╗  1280px
║  ┌──────────────────┐  ┌─────────────────────────────────────────────────────┐  ║
║  │  [Sc] ADMIN      │  │  DASHBOARD                         ●  Carlos     ⚙️  │  ║
║  │  SCALARIO        │  │  Mercredi 09/05/2026 · 15h20                        │  ║
║  │  ────────────────│  └─────────────────────────────────────────────────────┘  ║
║  │                  │                                                           ║
║  │  📊 Dashboard [●]│  (zone contenu)                                           ║
║  │  🏢 Tenants      │                                                           ║
║  │  👤 Intégrateurs │                                                           ║
║  │  💰 Facturation  │                                                           ║
║  │  📡 Monitoring   │                                                           ║
║  │                  │                                                           ║
║  │  ────────────────│                                                           ║
║  │  ⚙️ Paramètres   │                                                           ║
║  │  🚪 Déconnexion  │                                                           ║
║  └──────────────────┘                                                           ║
╚══════════════════════════════════════════════════════════════════════════════════╝

Sidebar :
  width = 200px · bg color-neutral-900 · padding 16px
  Logo : [Sc] ADMIN · Inter 14sp 700 color-white
  Nav items : Inter 13sp 400 color-neutral-300 · hover bg neutral-700 · actif bg primary-600 color-white
  Separator : 1px neutral-700
```

---

## ÉTAT 1 — Dashboard Santé OK (Vue Principale)

```
╔══════════════════════════════════════════════════════════════════════════════════╗  1280px
║  ┌────────┐  ┌──────────────────────────────────────────────────────────────┐   ║
║  │ ADMIN  │  │  DASHBOARD                                    Carlos S.  ⚙️  │   ║  TopBar secondaire 56px
║  │ Sidebar│  └──────────────────────────────────────────────────────────────┘   ║
║  │ (200px)│                                                                     ║
║  │        │  ── Mercredi 09 mai 2026 ────────────────────────────────────────  ║  PageHeader Inter 20sp 700
║  │        │                                                                     ║
║  │  📊 [●]│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐ ┌──────┐ ║  ← 4 KPICards row
║  │  🏢    │  │ Tenants actifs │ │   MRR total    │ │  FCM delivery  │ │Erreur│ ║  gap 16px
║  │  👤    │  │      12        │ │  480 000 FCFA  │ │     97,3%      │ │  0   │ ║  Roboto Mono 32sp 700
║  │  💰    │  │   ↑ +2 vs M-1  │ │  ↑ +80 000/M  │ │  ✓ excellent   │ │  ✓ OK│ ║  Inter 13sp color-neutral-500
║  │  📡    │  └────────────────┘ └────────────────┘ └────────────────┘ └──────┘ ║
║  │        │  bg neutral-50  neutral-50             success-50            neutral-50
║  │        │                                                                     ║
║  │        │  ┌──────────────────────────────────┐  ┌───────────────────────┐   ║  2-col 60/40
║  │        │  │ MRR — 30 derniers jours          │  │  ACTIVITÉS RÉCENTES   │   ║
║  │        │  │ ───────────────────────────────  │  │  ─────────────────── │   ║
║  │        │  │ 500k┤          ╭─●              │  │  ● Tenant actif       │   ║
║  │        │  │ 450k┤    ╭─────╯               │  │  Blandine (Kouamé)    │   ║
║  │        │  │ 400k┤╭───╯                     │  │  il y a 2h · Kofi     │   ║
║  │        │  │ 350k┤╯                         │  │  ─────────────────── │   ║  ActivityList
║  │        │  │     └──────────────────────    │  │  ● Déploiement tenant │   ║
║  │        │  │     10/04───────────────09/05  │  │  Shop Aminata · 09h31 │   ║
║  │        │  └──────────────────────────────────┘  │  ─────────────────── │   ║
║  │        │  Roboto Mono 11sp axes                 │  ● Paiement reçu     │   ║
║  │        │                                        │  Boutique Kouamé     │   ║
║  │        │  ┌──────────────────────────────────┐  │  40 000 FCFA · hier  │   ║
║  │        │  │ Nouveaux tenants — 6 derniers mois│  └───────────────────────┘   ║
║  │        │  │ ───────────────────────────────  │                              ║
║  │        │  │  3 ┤ █   █   █   █   █   █      │  ┌───────────────────────┐   ║
║  │        │  │  2 ┤ █   █   █   █   █   █      │  │  ACCÈS RAPIDE         │   ║  Quick links
║  │        │  │  1 ┤ █   █   █   █   █   █      │  │  ─────────────────── │   ║
║  │        │  │    └──────────────────────────   │  │  → Tenants (12)       │   ║
║  │        │  │     Déc Jan Fév Mar Avr Mai     │  │  → Intégrateurs (3)   │   ║
║  │        │  └──────────────────────────────────┘  │  → Impayés (0)        │   ║
║  │        │                                        │  → Logs erreurs (0)   │   ║
║  └────────┘                                        └───────────────────────┘   ║
╚══════════════════════════════════════════════════════════════════════════════════╝

KPICards couleurs :
  Tenants actifs   : bg neutral-50  · val neutral-900 (neutre)
  MRR total        : bg neutral-50  · val neutral-900 (neutre)
  FCM delivery     : bg success-50  · val success-700 (> 95% = excellent)
  Erreurs actives  : bg neutral-50  · val neutral-900 · "✓ OK"

Alertes : absentes si tout est OK → zone invisible

ActivityList :
  ● bleu : déploiement nouveau tenant
  ● vert : paiement reçu
  ● ambre : warning
  ● rouge : erreur critique

ChartWidget axes Roboto Mono 10sp · valeurs FCFA abrégées (480k)
```

---

## ÉTAT 2 — Dashboard avec Alertes Critiques

```
╔══════════════════════════════════════════════════════════════════════════════════╗  1280px
║  ┌────────┐  ┌──────────────────────────────────────────────────────────────┐   ║
║  │ ADMIN  │  │  DASHBOARD                                    Carlos S.  ⚙️  │   ║
║  │        │  └──────────────────────────────────────────────────────────────┘   ║
║  │        │                                                                     ║
║  │        │  ┌────────────────────────────────────────────────────────────────┐ ║  ← AlertBanner rouge pleine largeur
║  │        │  │ ⛔ ALERTE CRITIQUE — Erreurs sync Drift actives (3 tenants)    │ ║  bg danger-100 · border-l 4px danger-500
║  │        │  │    Shop Aminata · Boutique Kouamé · Épicerie Centrale          │ ║  Inter 14sp 600 danger-800
║  │        │  │    [  Voir dans Monitoring  ]                                  │ ║
║  │        │  └────────────────────────────────────────────────────────────────┘ ║  radius-md · padding 14px
║  │        │                                                                     ║
║  │        │  ┌────────────────────────────────────────────────────────────────┐ ║  ← AlertBanner ambre
║  │        │  │ ⚠️ FCM delivery rate : 84% (seuil < 90%) — 24 dernières heures │ ║  bg warning-100 · border-l 4px warning-500
║  │        │  │    [  Voir logs FCM  ]                                          │ ║  Inter 13sp 600 warning-800
║  │        │  └────────────────────────────────────────────────────────────────┘ ║
║  │        │                                                                     ║
║  │  📊 [●]│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐ ┌──────┐ ║
║  │  🏢    │  │ Tenants actifs │ │   MRR total    │ │  FCM delivery  │ │Erreur│ ║
║  │  👤    │  │      12        │ │  480 000 FCFA  │ │     84%        │ │  3   │ ║
║  │  💰    │  │   ↑ +2 vs M-1  │ │  ↑ +80 000/M  │ │  ⚠️ < seuil    │ │  ⛔  │ ║
║  │  📡    │  └────────────────┘ └────────────────┘ └────────────────┘ └──────┘ ║
║  │        │  bg neutral-50  neutral-50             warning-50            danger-50
║  │        │                                        val warning-700       val danger-700
║  │        │                                                                     ║
║  │        │  [ChartWidgets MRR + Tenants identiques ÉTAT 1 ...]                ║
║  │        │                                                                     ║
║  └────────┘                                                                     ║
╚══════════════════════════════════════════════════════════════════════════════════╝

Alertes système empilées (rouge au-dessus de ambre) :
  critiques en rouge toujours first
  warnings en ambre ensuite
  CTA inline → lien section concernée (Monitoring, Facturation...)

KPICards mise à jour :
  FCM delivery : bg warning-50 val warning-700 (< 90%)
  Erreurs actives : bg danger-50 val danger-700 (= "3 ⛔")
```

---

## Annotations — Dashboard Admin

### Typographie

| Élément | Token DS | Font | Size | Weight | Couleur |
|---------|----------|------|------|--------|---------|
| Logo sidebar | `font-logo` | Inter | 14sp | 700 | color-white |
| Nav item | `text-body-sm` | Inter | 13sp | 400 | neutral-300 / white (actif) |
| PageHeader | `font-page-title` | Inter | 20sp | 700 | color-neutral-900 |
| PageHeader date | `text-caption` | Inter | 13sp | 400 | color-neutral-500 |
| AlertBanner | `text-body-sm` | Inter | 14sp | 600 | par type |
| KPICard valeur | `font-kpi-value` | Roboto Mono | 32sp | 700 | par statut |
| KPICard variation | `text-caption` | Inter | 13sp | 400 | success-600/neutral-500 |
| ChartWidget axes | `font-mono-xs` | Roboto Mono | 10sp | 400 | color-neutral-400 |
| ActivityList item | `text-caption` | Inter | 13sp | 400 | color-neutral-700 |
| Quick link | `text-body-sm` | Inter | 13sp | 400 | color-primary-600 |

### Layout Dimensions

| Zone | Valeur |
|------|--------|
| Sidebar width | 200px |
| TopBar height | 56px |
| Contenu padding | 24px 32px |
| KPICards gap | 16px |
| ChartWidget height | 200px |
| AlertBanner padding | 14px 20px |
| Gap entre sections | 24px |

### Seuils Alertes Système

```
FCM delivery < 90% → warning ambre
FCM delivery < 85% → critique rouge
Erreurs sync > 0   → critique rouge
Erreurs sync > 5%  → critique rouge + push notification Carlos
API uptime < 99%   → warning ambre
Paiement retard > 30j → warning ambre (lien → A04)
```
