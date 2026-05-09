---
scenario: "A05"
sketch-type: hi-fi-ascii
platform: flutter-web-desktop
screen-width: 1280px+
font: Inter + Roboto Mono
states: [vue-globale-sante, vue-logs, detail-tenant-monitoring]
---

# Sketch Hi-Fi — A05 Monitoring (Admin Scalario)

> Surveillance en temps réel de la santé technique de la plateforme — sync Drift, FCM delivery, logs, alertes actives.
> Platform : Flutter Web desktop uniquement. Accès équipe Scalario.
> Entry : Dashboard A01 → nav "Monitoring" · ou depuis AlertBanner A01 → CTA "Voir dans Monitoring".

---

## ÉTAT 1 — Vue Globale Santé (Tout OK)

```
╔══════════════════════════════════════════════════════════════════════════════════╗  1280px
║  ┌────────┐  ┌──────────────────────────────────────────────────────────────┐   ║
║  │ ADMIN  │  │  MONITORING                                   Carlos S.  ⚙️  │   ║  TopBar 56px
║  │  📡 [●]│  └──────────────────────────────────────────────────────────────┘   ║
║  │        │                                                                     ║
║  │        │  MONITORING PLATEFORME · Dernière mise à jour : 09/05 15h20  ↺     ║  PageHeader Inter 20sp 700
║  │        │  ─────────────────────────────────────────────────────────────────  ║  ↺ = refresh manual
║  │        │                                                                     ║
║  │        │  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐ ┌──────┐ ║  ← 4 KPICards row
║  │        │  │ Sync Drift     │ │ FCM delivery   │ │ Erreurs actives│ │Uptime│ ║  gap 16px
║  │        │  │   100 %        │ │    97,3 %      │ │       0        │ │99,9% │ ║  Roboto Mono 32sp 700
║  │        │  │ ✓ 24h · 12/12  │ │ ✓ excellent 7j │ │   ✓ aucune     │ │30j ✓ │ ║  Inter 13sp neutral-500
║  │        │  └────────────────┘ └────────────────┘ └────────────────┘ └──────┘ ║
║  │        │  bg success-50     bg success-50        bg neutral-50      success-50║
║  │        │  val success-700   val success-700       val neutral-900   success-700║
║  │        │                                                                     ║
║  │        │  ┌──────────────────────────────────────────────────────────────┐   ║  ← StatusTable tenants
║  │        │  │  SANTÉ DES TENANTS · 12 tenants · Tout OK                   │   ║  SectionHeader Inter 14sp 600
║  │        │  │  ─────────────────────────────────────────────────────────── │   ║
║  │        │  │  Tenant              Dernière sync    FCM 7j   Erreurs Statut│   ║  en-tête Inter 12sp 600 neutral-600
║  │        │  │  ─────────────────────────────────────────────────────────── │   ║
║  │        │  │  Boutique Kouamé    15h19 (il y a 1min) 99,1%   0    ✓ OK  ›│   ║
║  │        │  │  Shop Aminata       15h18 (il y a 2min) 98,7%   0    ✓ OK  ›│   ║
║  │        │  │  Épicerie Centrale  15h17 (il y a 3min) 97,4%   0    ✓ OK  ›│   ║
║  │        │  │  Marché du Plateau  15h16 (il y a 4min) 98,2%   0    ✓ OK  ›│   ║
║  │        │  │  Super Yidaba       15h15 (il y a 5min) 96,5%   0    ✓ OK  ›│   ║
║  │        │  │  [... 7 autres tenants — tous OK ...]                          │   ║
║  │        │  └──────────────────────────────────────────────────────────────┘   ║
║  │        │                                                                     ║
║  │        │  ┌──────────────────────────────────────────────────────────────┐   ║  ← LogPreview (3 derniers)
║  │        │  │  DERNIERS ÉVÉNEMENTS SYSTÈME                  [Voir tous →]  │   ║  SectionHeader + CTA link
║  │        │  │  ─────────────────────────────────────────────────────────── │   ║
║  │        │  │  15h19  INFO    Boutique Kouamé   Sync Drift OK (143 enr.)  │   ║  Inter 12sp
║  │        │  │  15h18  INFO    Shop Aminata      FCM delivered (2 msg)      │   ║  Roboto Mono timestamps
║  │        │  │  15h17  INFO    Épicerie Centrale Sync Drift OK (67 enr.)   │   ║
║  │        │  └──────────────────────────────────────────────────────────────┘   ║
║  └────────┘                                                                     ║
╚══════════════════════════════════════════════════════════════════════════════════╝

StatusTable santé :
  ✓ OK    : StatusBadge bg success-100 · color success-700 · Inter 11sp 500
  ⚠ Warn  : StatusBadge bg warning-100 · color warning-700
  ⛔ Err  : StatusBadge bg danger-100  · color danger-700
  Timestamps : Roboto Mono 12sp neutral-600 (toujours format heure + delta "il y a Xmin")
  FCM % : Roboto Mono 12sp — vert si >95% · ambre si 85-95% · rouge si <85%
  › = clic → ÉTAT 3 détail tenant monitoring
```

---

## ÉTAT 2 — Vue Globale Santé (Alertes Actives)

```
╔══════════════════════════════════════════════════════════════════════════════════╗  1280px
║  ┌────────┐  ┌──────────────────────────────────────────────────────────────┐   ║
║  │ ADMIN  │  │  MONITORING                                   Carlos S.  ⚙️  │   ║
║  │  📡 [●]│  └──────────────────────────────────────────────────────────────┘   ║
║  │        │                                                                     ║
║  │        │  ┌────────────────────────────────────────────────────────────────┐ ║  ← AlertBanner rouge
║  │        │  │ ⛔ 3 ERREURS CRITIQUES — Sync Drift échouée (> 3 tentatives)   │ ║  bg danger-100 · border-l 4px danger-500
║  │        │  │    Shop Aminata · Boutique Kouamé · Épicerie Centrale           │ ║  Inter 14sp 600 danger-800
║  │        │  │    [  Forcer resync tous  ]  [  Voir logs  ]                   │ ║  radius-md · padding 14px
║  │        │  └────────────────────────────────────────────────────────────────┘ ║
║  │        │                                                                     ║
║  │        │  ┌────────────────────────────────────────────────────────────────┐ ║  ← AlertBanner ambre
║  │        │  │ ⚠️ FCM delivery rate : 84% (seuil 85%) — 24 dernières heures   │ ║  bg warning-100 · border-l 4px warning-500
║  │        │  │    [  Voir logs FCM  ]                                          │ ║  Inter 13sp 600 warning-800
║  │        │  └────────────────────────────────────────────────────────────────┘ ║
║  │        │                                                                     ║
║  │        │  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐ ┌──────┐ ║  ← 4 KPICards row
║  │        │  │ Sync Drift     │ │ FCM delivery   │ │ Erreurs actives│ │Uptime│ ║
║  │        │  │    75 %        │ │    84 %        │ │       3        │ │99,9% │ ║  Roboto Mono 32sp 700
║  │        │  │ ⛔ 3/12 err.   │ │ ⚠️ < seuil 24h │ │   ⛔ critiques │ │30j ✓ │ ║
║  │        │  └────────────────┘ └────────────────┘ └────────────────┘ └──────┘ ║
║  │        │  bg danger-50     bg warning-50         bg danger-50       success-50║
║  │        │  val danger-700   val warning-700        val danger-700   success-700║
║  │        │                                                                     ║
║  │        │  ┌──────────────────────────────────────────────────────────────┐   ║  ← StatusTable (tenants en erreur en haut)
║  │        │  │  SANTÉ DES TENANTS · 12 tenants · 3 en erreur               │   ║
║  │        │  │  ─────────────────────────────────────────────────────────── │   ║
║  │        │  │  Tenant              Dernière sync    FCM 7j   Erreurs Statut│   ║
║  │        │  │  ─────────────────────────────────────────────────────────── │   ║
║  │        │  │  Shop Aminata       14h32 (53min)   84,1%    3   ⛔ Erreur ›│   ║  ligne bg danger-50
║  │        │  │  Boutique Kouamé    14h45 (35min)   81,3%    3   ⛔ Erreur ›│   ║  tri : erreurs en haut
║  │        │  │  Épicerie Centrale  14h50 (30min)   79,8%    3   ⛔ Erreur ›│   ║
║  │        │  │  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │   ║  séparateur visuel
║  │        │  │  Marché du Plateau  15h16 (4min)    98,2%    0   ✓ OK  ›    │   ║
║  │        │  │  Super Yidaba       15h15 (5min)    96,5%    0   ✓ OK  ›    │   ║
║  │        │  │  [... 7 autres tenants — OK ...]                               │   ║
║  │        │  └──────────────────────────────────────────────────────────────┘   ║
║  └────────┘                                                                     ║
╚══════════════════════════════════════════════════════════════════════════════════╝

StatusTable en erreur :
  lignes ⛔ : bg danger-50 (tinte rouge légère toute la ligne)
  tri par défaut : erreurs d'abord → séparateur tirets → OK ensuite
  CTA "Forcer resync tous" inline dans AlertBanner : bg danger-600 color white
  CTA "Voir logs" : lien → ÉTAT 3 vue logs filtré sur "Critique"
```

---

## ÉTAT 3 — Vue Logs (Filtrée)

```
╔══════════════════════════════════════════════════════════════════════════════════╗  1280px
║  ┌────────┐  ┌──────────────────────────────────────────────────────────────┐   ║
║  │ ADMIN  │  │  MONITORING › LOGS                            Carlos S.  ⚙️  │   ║  Breadcrumb
║  │  📡 [●]│  └──────────────────────────────────────────────────────────────┘   ║
║  │        │                                                                     ║
║  │        │  LOGS SYSTÈME · Temps réel · Auto-refresh 30s               ↺ Live ║  PageHeader
║  │        │  ─────────────────────────────────────────────────────────────────  ║
║  │        │                                                                     ║
║  │        │  ┌──────────────────────────────────────────────────────────────┐   ║  ← SearchBar
║  │        │  │ 🔍 Rechercher par tenant, type d'erreur, message...          │   ║  h=40px · radius-md · border neutral-200
║  │        │  └──────────────────────────────────────────────────────────────┘   ║
║  │        │                                                                     ║
║  │        │  TYPE :  [ Tous ] [ ⚡ Sync ] [ 🔔 FCM ] [ 🔐 Auth ] [ 🌐 API ] [ 🔗 Webhook ]  ║  FilterChips type
║  │        │                                                                     ║
║  │        │  SÉVÉRITÉ : [ ⛔ Critique ] [▓ ⚠️ Warning ▓] [ ℹ Info ]            ║  FilterChips sévérité (Warning actif)
║  │        │                                                                     ║
║  │        │  ┌──────────────────────────────────────────────────────────────┐   ║  ← LogList
║  │        │  │ TIMESTAMP         SÉVÉRITÉ  TENANT              TYPE    MSG  │   ║  en-tête Inter 12sp 600 neutral-600
║  │        │  │ ─────────────────────────────────────────────────────────── │   ║
║  │        │  │                                                              │   ║
║  │        │  │ 15:20:14.321   ⛔ CRITIQUE  Shop Aminata        SYNC         │   ║  ← LogItem critique
║  │        │  │   Drift sync échec — tentative 4/5 — DriftException: conn   │   ║  bg danger-50 · border-l 3px danger-500
║  │        │  │   refused at 192.168.1.45:8080 after 5000ms timeout         │   ║  Inter 12sp neutral-700
║  │        │  │   [  Voir détail  ]  [  Forcer resync  ]                    │   ║  CTAs inline
║  │        │  │                                                              │   ║
║  │        │  │ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │   ║
║  │        │  │                                                              │   ║
║  │        │  │ 15:19:57.804   ⛔ CRITIQUE  Boutique Kouamé     SYNC         │   ║
║  │        │  │   Drift sync échec — tentative 4/5 — DriftException: conn   │   ║  bg danger-50 · border-l 3px danger-500
║  │        │  │   refused at 192.168.1.45:8080 after 5000ms timeout         │   ║
║  │        │  │   [  Voir détail  ]  [  Forcer resync  ]                    │   ║
║  │        │  │                                                              │   ║
║  │        │  │ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │   ║
║  │        │  │                                                              │   ║
║  │        │  │ 14:55:03.118   ⚠️ WARNING   Tous tenants         FCM         │   ║  ← LogItem warning
║  │        │  │   FCM delivery rate 84% sur 24h — seuil 85% — 143 messages  │   ║  bg warning-50 · border-l 3px warning-500
║  │        │  │   non livrés sur 889 envois                                  │   ║  Inter 12sp neutral-700
║  │        │  │   [  Voir logs FCM  ]                                       │   ║
║  │        │  │                                                              │   ║
║  │        │  │ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │   ║
║  │        │  │                                                              │   ║
║  │        │  │ 13:30:45.201   ⚠️ WARNING   Super Yidaba          AUTH       │   ║  ← LogItem warning auth
║  │        │  │   KYC échoué répété — 3 tentatives en 10min                  │   ║  bg warning-50 · border-l 3px warning-500
║  │        │  │   User: moussa.trial@yidaba.com · IP: 197.234.12.44         │   ║  Roboto Mono 11sp pour IP/email
║  │        │  │   [  Voir profil  ]  [  Bloquer IP  ]                       │   ║
║  │        │  │                                                              │   ║
║  │        │  └──────────────────────────────────────────────────────────────┘   ║
║  │        │                                                                     ║
║  │        │  Affichage : 3 de 47 warnings · [ Charger plus ]                   ║  Inter 12sp neutral-500 · pagination lazy
║  └────────┘                                                                     ║
╚══════════════════════════════════════════════════════════════════════════════════╝

LogItem structure :
  TIMESTAMP : Roboto Mono 12sp 400 neutral-500 (format HH:mm:ss.ms)
  SÉVÉRITÉ badge : Inter 11sp 600 (CRITIQUE danger-700 / WARNING warning-700 / INFO neutral-500)
  TENANT : Inter 12sp 600 neutral-800
  TYPE : Inter 11sp 400 neutral-500 italic
  Message ligne 1 : Inter 13sp 500 neutral-800 (résumé)
  Message ligne 2 : Inter 12sp 400 neutral-600 (détail technique)
  Roboto Mono 11sp : identifiants, IP, emails dans les messages
  CTAs inline : Inter 12sp 500 → lien texte color-primary-600 underline

Border-l par sévérité :
  CRITIQUE : border-l 3px danger-500 · bg danger-50
  WARNING  : border-l 3px warning-500 · bg warning-50
  INFO     : border-l 3px neutral-200 · bg white

Auto-refresh : toutes les 30s · header "↺ Live" clignote 500ms à chaque refresh
```

---

## ÉTAT 4 — Vue Logs — LogItem Expandé (Critique)

```
╔══════════════════════════════════════════════════════════════════════════════════╗  1280px
║  ┌────────┐  ┌──────────────────────────────────────────────────────────────┐   ║
║  │ ADMIN  │  │  MONITORING › LOGS                            Carlos S.  ⚙️  │   ║
║  │  📡 [●]│  └──────────────────────────────────────────────────────────────┘   ║
║  │        │                                                                     ║
║  │        │  [SearchBar + FilterChips TYPE + SÉVÉRITÉ identiques ÉTAT 3 ...]    ║
║  │        │                                                                     ║
║  │        │  ┌──────────────────────────────────────────────────────────────┐   ║  ← LogItem CRITIQUE expandé
║  │        │  │ 15:20:14.321   ⛔ CRITIQUE  Shop Aminata        SYNC         │   ║  bg danger-50 · border-l 3px danger-500
║  │        │  │ ─────────────────────────────────────────────────────────── │   ║
║  │        │  │  Résumé : Drift sync échec — tentative 4/5                  │   ║  Inter 13sp 600 neutral-800
║  │        │  │                                                              │   ║
║  │        │  │  ┌──────────────────────────────────────────────────────┐   │   ║  ← StackTrace panel
║  │        │  │  │ STACK TRACE                                          │   │   ║  bg neutral-900 · radius-md · padding 12px
║  │        │  │  │ DriftException: ConnectionRefused                    │   │   ║  Roboto Mono 11sp color-neutral-100
║  │        │  │  │   at SyncService.push (sync_service.dart:142)        │   │   ║  monospace stack trace
║  │        │  │  │   at BackendAdapter.flush (adapter.dart:88)          │   │   ║
║  │        │  │  │   at DriftDatabase.sync (drift_db.dart:234)          │   │   ║
║  │        │  │  │ Cause: SocketException: Connection refused            │   │   ║
║  │        │  │  │   Host: 192.168.1.45 Port: 8080 Timeout: 5000ms      │   │   ║
║  │        │  │  └──────────────────────────────────────────────────────┘   │   ║
║  │        │  │                                                              │   ║
║  │        │  │  Contexte tenant :                                          │   ║
║  │        │  │  Tenant ID    : tenant_shop_aminata_001           Roboto Mono│   ║
║  │        │  │  Dernière sync: 14h32 (il y a 48 min)             Roboto Mono│   ║
║  │        │  │  Tentatives   : 4 / 5 max                                   │   ║
║  │        │  │  Nb enregistrements en attente : 89                         │   ║
║  │        │  │  Utilisateurs actifs tenant : 0 (offline probable)          │   ║
║  │        │  │                                                              │   ║
║  │        │  │  [  Voir détail tenant  ]  [  Forcer resync maintenant  ]   │   ║  CTAs
║  │        │  │  color-primary-600        bg danger-600 color-white          │   ║
║  │        │  └──────────────────────────────────────────────────────────────┘   ║
║  │        │                                                                     ║
║  │        │  [Autres LogItems non expandés ...]                                  ║
║  └────────┘                                                                     ║
╚══════════════════════════════════════════════════════════════════════════════════╝

LogItem expandé :
  clic sur la ligne → expand/collapse (toggle)
  StackTrace bg neutral-900 (dark panel) pour lisibilité contraste élevé
  Roboto Mono 11sp color-neutral-100 pour stack trace
  Contexte tenant : Roboto Mono 12sp pour IDs et valeurs numériques
  "Forcer resync maintenant" = action directe sans dialogue (non destructif)
    → spinner inline dans le bouton pendant l'action
    → succès : log INFO ajouté "Resync forcé par carlos_s"
    → échec : AlertBanner ambre dans le log item
```

---

## ÉTAT 5 — Détail Tenant (Onglet Monitoring)

```
╔══════════════════════════════════════════════════════════════════════════════════╗  1280px
║  ┌────────┐  ┌──────────────────────────────────────────────────────────────┐   ║
║  │ ADMIN  │  │  TENANTS › SHOP AMINATA › MONITORING         Carlos S.  ⚙️  │   ║  Breadcrumb
║  │  📡 [●]│  └──────────────────────────────────────────────────────────────┘   ║
║  │        │                                                                     ║
║  │        │  ┌────────────────────────────────────────────────────────────────┐ ║  ← PageHeader tenant
║  │        │  │  🏢 SHOP AMINATA                   ⛔ Erreur sync depuis 48min │ ║  Inter 20sp 700 + badge danger
║  │        │  │  Cocody, Abidjan · Kofi Mensah · retail_fresh_produce.json     │ ║
║  │        │  └────────────────────────────────────────────────────────────────┘ ║
║  │        │                                                                     ║
║  │        │  ─── [  Info  ] [  Facturation  ] [▓  Monitoring  ▓] [  Logs  ] ─── ║  Tabs tenant · Monitoring actif
║  │        │                                                                     ║
║  │        │  ┌────────────────────────────────────────────────────────────────┐ ║  ← AlertBanner critique
║  │        │  │ ⛔ Sync Drift échouée depuis 14h32 — 4 tentatives infructueuses│ ║  bg danger-100 · border-l 4px danger-500
║  │        │  │    89 enregistrements en attente de synchronisation            │ ║  Inter 13sp 600 danger-800
║  │        │  └────────────────────────────────────────────────────────────────┘ ║
║  │        │                                                                     ║
║  │        │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────┐  ║  ← 4 KPICards
║  │        │  │ Dernière sync│ │ FCM 7 jours  │ │ Err. actives │ │ Uptime   │  ║
║  │        │  │  14h32       │ │   84,1 %     │ │      3       │ │  99,9%   │  ║  Roboto Mono 24sp 700
║  │        │  │  ⛔ 48min ago│ │  ⚠️ < seuil  │ │  ⛔ critiques│ │  ✓ OK   │  ║
║  │        │  └──────────────┘ └──────────────┘ └──────────────┘ └──────────┘  ║
║  │        │  bg danger-50     bg warning-50       bg danger-50     success-50   ║
║  │        │  val danger-700   val warning-700      val danger-700  success-700  ║
║  │        │                                                                     ║
║  │        │  ┌─────────────────────────────────────┐  ┌──────────────────────┐ ║  2-col
║  │        │  │  LOGS RÉCENTS — SHOP AMINATA        │  │  DIAGNOSTICS         │ ║
║  │        │  │  ─────────────────────────────────  │  │  ─────────────────── │ ║
║  │        │  │ 15:20  ⛔ Drift sync échec T4/5    │  │  Connectivité tenant  │ ║
║  │        │  │ 15:05  ⛔ Drift sync échec T3/5    │  │  ○ Ping API           │ ║  ○ = failed
║  │        │  │ 14:50  ⛔ Drift sync échec T2/5    │  │  ○ Backend reachable  │ ║
║  │        │  │ 14h35  ⛔ Drift sync échec T1/5    │  │  ✓ Drift DB locale OK │ ║  ✓ = ok
║  │        │  │ 14h32  ℹ️ Sync OK (143 enr.)       │  │  ✓ FCM token valide   │ ║
║  │        │  │ 14h15  ℹ️ FCM delivered (1 msg)    │  │  ✓ JWT valide         │ ║
║  │        │  │ 14h02  ℹ️ User login OK (Ibrahim)  │  │                       │ ║
║  │        │  │                                    │  │  Cause probable :     │ ║
║  │        │  │  [  Voir tous les logs  →  ]       │  │  Réseau tenant hors   │ ║  Inter 13sp neutral-700
║  │        │  └─────────────────────────────────────┘  │  ligne · backend API  │ ║
║  │        │                                           │  inaccessible depuis  │ ║
║  │        │                                           │  l'appareil tenant.   │ ║
║  │        │                                           │                       │ ║
║  │        │                                           │  [  Forcer resync  ]  │ ║  ActionButton
║  │        │                                           │  bg danger-600 white  │ ║
║  │        │                                           │  Inter 13sp 600       │ ║
║  │        │                                           └──────────────────────┘ ║
║  └────────┘                                                                     ║
╚══════════════════════════════════════════════════════════════════════════════════╝

Tabs tenant (contexte navigation A02 → onglet Monitoring) :
  Info / Facturation / Monitoring (actif) / Logs
  onglet actif : bg primary-600 color-white · Inter 13sp 500
  onglets inactifs : color-neutral-600 hover bg neutral-100

DiagnosticsPanel (colonne droite) :
  ✓ vert = test réussi → Inter 13sp success-700
  ○ rouge = test échoué → Inter 13sp danger-700
  Cause probable : Inter 13sp 400 neutral-700 (IA-généré, non bloquant)

"Forcer resync" ActionButton :
  bg danger-600 color-white · Inter 13sp 600 · radius-md · padding 10px 20px
  POST /admin/tenants/{id}/force-sync
  → spinner inline pendant T+0 → T+2s
  → succès : nouveau log ℹ️ "Resync forcé par carlos_s à 15h21"
  → KPICard "Dernière sync" se met à jour
```

---

## ÉTAT 6 — Vue Globale Santé — Tous OK (post-résolution)

```
╔══════════════════════════════════════════════════════════════════════════════════╗  1280px
║  ┌────────┐  ┌──────────────────────────────────────────────────────────────┐   ║
║  │ ADMIN  │  │  MONITORING                                   Carlos S.  ⚙️  │   ║
║  │  📡    │  └──────────────────────────────────────────────────────────────┘   ║  ← badge [●] disparaît
║  │        │                                                                     ║
║  │        │  ┌────────────────────────────────────────────────────────────────┐ ║  ← AlertBanner succès
║  │        │  │ ✅ Resync forcé réussi — Shop Aminata synchronisé (89 enr.)   │ ║  bg success-100 · border-l 3px success-500
║  │        │  │    FCM delivery de retour à 97,1% — seuil dépassé             │ ║  Inter 13sp 600 success-800
║  │        │  └────────────────────────────────────────────────────────────────┘ ║  auto-dismiss 5s (long car résolution critique)
║  │        │                                                                     ║
║  │        │  MONITORING PLATEFORME · Dernière mise à jour : 09/05 15h23  ↺     ║
║  │        │  ─────────────────────────────────────────────────────────────────  ║
║  │        │                                                                     ║
║  │        │  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐ ┌──────┐ ║
║  │        │  │ Sync Drift     │ │ FCM delivery   │ │ Erreurs actives│ │Uptime│ ║
║  │        │  │   100 %        │ │    97,1 %      │ │       0        │ │99,9% │ ║
║  │        │  │ ✓ 24h · 12/12  │ │ ✓ excellent    │ │   ✓ aucune     │ │30j ✓ │ ║
║  │        │  └────────────────┘ └────────────────┘ └────────────────┘ └──────┘ ║
║  │        │  bg success-50     bg success-50        bg neutral-50      success-50║
║  │        │                                                                     ║
║  │        │  [StatusTable tenants — tous OK ...]                                ║
║  └────────┘                                                                     ║
╚══════════════════════════════════════════════════════════════════════════════════╝

Post-résolution :
  AlertBanner succès auto-dismiss 5s (plus long car message important)
  Badge [●] rouge dans sidebar nav disparaît (erreurs = 0)
  KPICards retournent aux couleurs success/neutral (plus danger/warning)
  Audit log automatique : "Resync forcé · Carlos S. · 15h21 · Shop Aminata (89 enr. sync)"
```

---

## Annotations — Monitoring

### Typographie

| Élément | Token DS | Font | Size | Weight | Couleur |
|---------|----------|------|------|--------|---------|
| PageHeader | `font-page-title` | Inter | 20sp | 700 | color-neutral-900 |
| SectionHeader | `text-body-md` | Inter | 14sp | 600 | color-neutral-800 |
| KPICard valeur | `font-kpi-value` | Roboto Mono | 32sp | 700 | par statut |
| KPICard valeur (détail) | `font-kpi-value-sm` | Roboto Mono | 24sp | 700 | par statut |
| KPICard sous-titre | `text-caption` | Inter | 13sp | 400 | color-neutral-500 |
| TableHeader | `text-overline` | Inter | 12sp | 600 | color-neutral-600 |
| TableRow | `text-body-sm` | Inter | 13sp | 400 | color-neutral-800 |
| Timestamp log | `font-mono-xs` | Roboto Mono | 12sp | 400 | color-neutral-500 |
| Tenant/type log | `text-body-sm` | Inter | 12sp | 600 | color-neutral-800 |
| Log message résumé | `text-body-sm` | Inter | 13sp | 500 | color-neutral-800 |
| Log message détail | `text-body-sm` | Inter | 12sp | 400 | color-neutral-600 |
| Stack trace | `font-mono-xs` | Roboto Mono | 11sp | 400 | color-neutral-100 |
| IDs / IP / emails | `font-mono-sm` | Roboto Mono | 11sp | 400 | color-neutral-600 |
| AlertBanner critique | `text-body-sm` | Inter | 14sp | 600 | color-danger-800 |
| AlertBanner warning | `text-body-sm` | Inter | 13sp | 600 | color-warning-800 |
| AlertBanner succès | `text-body-sm` | Inter | 13sp | 600 | color-success-800 |
| FilterChip actif | `text-caption` | Inter | 12sp | 600 | color-white |
| FilterChip inactif | `text-caption` | Inter | 12sp | 400 | color-neutral-600 |
| Tab actif | `text-body-sm` | Inter | 13sp | 500 | color-white |
| CTA inline log | `text-body-sm` | Inter | 12sp | 500 | color-primary-600 |

### Espacement

| Zone | Valeur |
|------|--------|
| Sidebar width | 200px |
| TopBar height | 56px |
| Contenu padding | 24px 32px |
| KPICards gap | 16px |
| LogItem padding | 16px 20px |
| LogItem gap entre lignes | 0 (border séparateur) |
| StackTrace panel padding | 12px |
| FilterChips gap | 8px |
| Tabs hauteur | 40px |
| AlertBanner padding | 14px 20px |
| Gap entre sections | 24px |
| 2-col gap (logs/diag) | 24px |
| DiagnosticsPanel padding | 16px |

### Composants DS référencés

| Composant | Fichier DS | Usage |
|-----------|------------|-------|
| `KPICard` | 02-data-display.md | Santé globale + détail tenant |
| `DataTable` / `StatusTable` | 02-data-display.md | Tenants avec tri erreurs-first |
| `StatusBadge` | 02-data-display.md | OK/warning/erreur par tenant |
| `LogItem` | 02-data-display.md | Entrée log expandable |
| `AlertBanner` | 06-feedback.md | Alertes critiques + warnings + succès |
| `FilterChips` | 03-form-inputs.md | Type log (×5) + sévérité (×3) |
| `SearchBar` | 03-form-inputs.md | Recherche libre logs |
| `ActionButton` | 05-actions.md | "Forcer resync" destructif |
| `Tabs` | 08-navigation-layout.md | Onglets tenant (Info/Facturation/Monitoring/Logs) |
| `SectionHeader` | 02-data-display.md | Titres sections internes |

### Seuils Alertes Monitoring

```
Sync Drift :
  < 1h depuis dernière sync  → ✓ OK (success)
  1h–3h depuis dernière sync → ⚠️ Warning ambre (KPICard warning-50)
  > 3h depuis dernière sync  → ⛔ Critique rouge (KPICard danger-50)
  > 3 tentatives sync échoué → AlertBanner A01 + badge [●] nav sidebar

FCM delivery rate (7j) :
  > 95%  → ✓ OK (success-700)
  90-95% → ✓ Bon (neutral-900, pas d'alerte)
  85-90% → ⚠️ Warning ambre
  < 85%  → ⛔ Critique rouge + AlertBanner A01

Erreurs actives :
  0     → ✓ aucune (neutral-50)
  ≥ 1   → KPICard danger-50 + badge [●] nav sidebar
  > 10% tenants simultané → AlertBanner pleine largeur A01

Uptime API (30j) :
  > 99% → ✓ OK (success)
  < 99% → ⚠️ Warning ambre
  < 95% → ⛔ Critique rouge

Auth KYC :
  > 3 échecs en 10min (même user) → WARNING log + alerte admin
```

### Flux "Forcer Resync"

```
Carlos clique "Forcer resync maintenant" :
  T+0ms   : POST /admin/tenants/{id}/force-sync
            spinner inline dans le bouton
  T+0–2s  : backend push message sync vers app tenant
  T+2s    : réponse 200 OK ou erreur
    → succès : log ℹ️ "Resync forcé par carlos_s" ajouté
               KPICard "Dernière sync" mise à jour
               si erreurs = 0 → badge [●] disparaît nav
    → échec  : AlertBanner ambre "Resync impossible — tenant hors ligne"
               log ⚠️ ajouté
               bouton de nouveau actif

Audit trail : forced_sync_by = "carlos_s" · forced_sync_at = timestamp
```

### Navigation Sidebar — Badge [●]

```
Sidebar nav item "📡 Monitoring" :
  [●] rouge = badge dot visible si erreurs_actives > 0
  → badge disparaît quand erreurs = 0
  → même logique que badge [●] sur "🏢 Tenants" pour impayés

Badge simultanés possibles :
  📡 Monitoring [●] = erreurs sync ou FCM hors seuil
  🏢 Tenants [●]   = tenant impayé ou suspendu
  💰 Facturation [●] = paiement retard > 30j
```

### Types de Logs par Catégorie

```
SYNC (⚡) :
  INFO    : Drift sync OK (X enregistrements) ← vert standard
  WARNING : Sync lente (>3s) ou partielle
  CRITIQUE: Sync échouée (DriftException / ConnectionRefused)

FCM (🔔) :
  INFO    : Message FCM délivré (X/X)
  WARNING : Taux delivery < 85% sur 24h
  CRITIQUE: FCM token invalide ou quota dépassé

AUTH (🔐) :
  INFO    : Login OK + logout OK
  WARNING : KYC échoué répété (>3 en 10min)
  CRITIQUE: JWT forgé détecté / brute force

API (🌐) :
  INFO    : Request OK (médiane < 500ms)
  WARNING : Request lente (500ms–5s)
  CRITIQUE: Timeout (>5s médiane) / 5xx

WEBHOOK (🔗) :
  INFO    : Webhook délivré OK
  WARNING : Retry webhook (2e tentative)
  CRITIQUE: Webhook échoué (3 tentatives)
```
