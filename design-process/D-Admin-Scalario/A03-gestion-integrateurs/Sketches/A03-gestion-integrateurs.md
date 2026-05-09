---
scenario: "A03"
sketch-type: hi-fi-ascii
platform: flutter-web-desktop
screen-width: 1280px+
font: Inter + Roboto Mono
states: [liste-integrateurs, detail-integrateur, certification]
---

# Sketch Hi-Fi — A03 Gestion Intégrateurs (Admin Scalario)

> Certification, suivi performance et gestion des intégrateurs certifiés.
> Platform : Flutter Web desktop uniquement. Accès équipe Scalario.
> Entry : Dashboard A01 → nav "Intégrateurs".

---

## ÉTAT 1 — Liste Intégrateurs

```
╔══════════════════════════════════════════════════════════════════════════════════╗  1280px
║  ┌────────┐  ┌──────────────────────────────────────────────────────────────┐   ║
║  │ ADMIN  │  │  INTÉGRATEURS                                 Carlos S.  ⚙️  │   ║
║  │  👤 [●]│  └──────────────────────────────────────────────────────────────┘   ║
║  │        │                                                                     ║
║  │        │  GESTION INTÉGRATEURS · 3 certifiés · 1 en attente                  ║  PageHeader
║  │        │  ─────────────────────────────────────────────────────────────────  ║
║  │        │                                                                     ║
║  │        │  [ Tous (4) ] [ ✓ Certifiés (3) ] [ ⏳ En attente (1) ] [ ⛔ Suspendus (0) ]  ║  FilterChips
║  │        │                                                                     ║
║  │        │  ┌───────────────────────────────────────────────────────────────┐  ║  ← DataTable intégrateurs
║  │        │  │ Nom                  Zone          Clients  MRR gén.  Statut   │  ║
║  │        │  │ ─────────────────────────────────────────────────────────────  │  ║
║  │        │  │ Kofi Mensah         Abidjan-C      12       480k    ✓ Certifié ›│  ║
║  │        │  │ Amara Diallo        Bouaké          4       160k    ✓ Certifié ›│  ║
║  │        │  │ Fatoumata Ba        Abidjan-P       2        80k    ✓ Certifié ›│  ║
║  │        │  │ Moussa Traoré       Yamoussoukro    0         —     ⏳ En attente›│  ║  ← nouveau intégrateur à certifier
║  │        │  └───────────────────────────────────────────────────────────────┘  ║
║  │        │                                                                     ║
║  │        │  ┌───────────────────────┐  ┌───────────────────────────────────┐  ║  2-col info bas de page
║  │        │  │  🔔 CERTIFICATION      │  │  RÉMUNÉRATION                     │  ║
║  │        │  │  En attente : 1       │  │  Intégrateur : 60% MRR client     │  ║
║  │        │  │  Moussa Traoré        │  │  Scalario    : 40% MRR client     │  ║
║  │        │  │  Yamoussoukro         │  │                                   │  ║
║  │        │  │  [  Voir profil  ]    │  │  MRR total généré : 720 000 FCFA  │  ║  Roboto Mono 20sp 700
║  │        │  └───────────────────────┘  │  Part Scalario     : 288 000 FCFA │  ║
║  │        │                             └───────────────────────────────────┘  ║
║  └────────┘                                                                     ║
╚══════════════════════════════════════════════════════════════════════════════════╝

DataTable colonnes :
  MRR généré : Roboto Mono 13sp 700 (total MRR tenants assignés)
  Statut : StatusBadge (certifié/en-attente/suspendu)
  → pas de colonne Part intégrateur dans la liste (visible dans le détail)
```

---

## ÉTAT 2 — Détail Intégrateur (Kofi Mensah)

```
╔══════════════════════════════════════════════════════════════════════════════════╗  1280px
║  ┌────────┐  ┌──────────────────────────────────────────────────────────────┐   ║
║  │ ADMIN  │  │  INTÉGRATEURS › KOFI MENSAH                   Carlos S.  ⚙️  │   ║  Breadcrumb
║  │  👤 [●]│  └──────────────────────────────────────────────────────────────┘   ║
║  │        │                                                                     ║
║  │        │  ┌────────────────────────────────────────────────────────────────┐ ║  PageHeader intégrateur
║  │        │  │  👤 KOFI MENSAH                     ✓ Certifié depuis 01/04   │ ║
║  │        │  │  Abidjan-Cocody · +225 07 45 67 89 · kofi@scalario.local      │ ║  Inter 20sp 700 + badges
║  │        │  └────────────────────────────────────────────────────────────────┘ ║
║  │        │                                                                     ║
║  │        │  ┌──────────────┐ ┌──────────────┐ ┌───────────────┐ ┌──────────┐  ║  ← 4 KPICards
║  │        │  │ Clients actifs│ │ MRR généré   │ │ Part Kofi(60%)│ │Avg T2V   │  ║
║  │        │  │    12         │ │ 480 000 FCFA │ │  288 000 FCFA│ │  31 min  │  ║  Roboto Mono 24sp 700
║  │        │  │ ↑ +2 ce mois  │ │ ↑ +80k/mois  │ │  vs seuil 1h │ │ ✓ < 1h   │  ║  bg success-50 (T2V < 1h)
║  │        │  └──────────────┘ └──────────────┘ └───────────────┘ └──────────┘  ║
║  │        │                                                                     ║
║  │        │  ─────────────────────────────────────────────────────────────────  ║  Separator
║  │        │                                                                     ║
║  │        │  ┌────────────────────────────────────┐  ┌────────────────────────┐ ║  2-col
║  │        │  │  SES CLIENTS (12)                  │  │  INFORMATIONS          │ ║
║  │        │  │  ──────────────────────────────── │  │  ─────────────────────  │ ║
║  │        │  │  Boutique Kouamé    ✓ Actif  40k  │  │  Zone : Abidjan-Cocody  │ ║
║  │        │  │  Shop Aminata       ✓ Actif  40k  │  │  Tél  : +225 07 45 67  │ ║  Roboto Mono
║  │        │  │  Épicerie Centrale  ✓ Actif  40k  │  │  Cert : 01/04/2026     │ ║
║  │        │  │  Marché du Plateau  ✓ Actif  60k  │  │  Dernière activité :   │ ║
║  │        │  │  Super Yidaba       ⚠ Trial   —   │  │  09/05 10h31           │ ║  Roboto Mono
║  │        │  │  [... 7 autres ...]                │  │                        │ ║
║  │        │  └────────────────────────────────────┘  └────────────────────────┘ ║
║  │        │                                                                     ║
║  │        │  ACTIONS : [  💬 Contacter  ]  [  Transférer clients  ]  [  ⛔ Suspendre accès  ]  ║
║  └────────┘                                                                     ║
╚══════════════════════════════════════════════════════════════════════════════════╝

KPICard "Avg T2V" (Time-to-Value) :
  bg success-50 · val success-700 si < 1h (SLA cible Scalario)
  bg warning-50 · val warning-700 si 1h–2h
  bg danger-50  · val danger-700  si > 2h
  Roboto Mono 24sp 700

TenantList dans col gauche :
  même format DataTable condensé
  clic → A02 détail tenant
  MRR Roboto Mono 13sp
```

---

## ÉTAT 3 — Certification Nouvel Intégrateur

```
╔══════════════════════════════════════════════════════════════════════════════════╗  1280px
║  ┌────────┐  ┌──────────────────────────────────────────────────────────────┐   ║
║  │ ADMIN  │  │  INTÉGRATEURS › MOUSSA TRAORÉ                 Carlos S.  ⚙️  │   ║
║  │  👤 [●]│  └──────────────────────────────────────────────────────────────┘   ║
║  │        │                                                                     ║
║  │        │  ┌────────────────────────────────────────────────────────────────┐ ║  ← AlertBanner info
║  │        │  │ ⏳ Certification en attente — Moussa Traoré a soumis sa        │ ║  bg warning-100 · border-l 4px warning-500
║  │        │  │    candidature le 07/05/2026. Vérifiez son profil avant        │ ║  Inter 13sp 600 warning-800
║  │        │  │    de certifier.                                                │ ║
║  │        │  └────────────────────────────────────────────────────────────────┘ ║
║  │        │                                                                     ║
║  │        │  ┌────────────────────────────────────────────────────────────────┐ ║  PageHeader candidat
║  │        │  │  👤 MOUSSA TRAORÉ                    ⏳ En attente               │ ║
║  │        │  │  Yamoussoukro · +225 05 12 34 56                              │ ║
║  │        │  └────────────────────────────────────────────────────────────────┘ ║
║  │        │                                                                     ║
║  │        │  ┌──────────────────────────────────────────────────────────────┐   ║  ← CertificationChecklist
║  │        │  │  CHECKLIST CERTIFICATION                                     │   ║  bg neutral-50 · radius-md · padding 20px
║  │        │  │  ────────────────────────────────────────────────────────── │   ║
║  │        │  │  ✓  Identité vérifiée (CNI ou passeport)                    │   ║  ✓ = Admin a confirmé
║  │        │  │  ✓  Zone géographique déclarée (Yamoussoukro)               │   ║  ○ = pas encore
║  │        │  │  ✓  Téléphone vérifié (+225 05 12 34 56)                    │   ║
║  │        │  │  ✓  Formation Scalario complétée (certificat joint)         │   ║  Inter 13sp success-700
║  │        │  │  ○  Contrat partenariat signé (en attente)                  │   ║  Inter 13sp neutral-400 (non fait)
║  │        │  └──────────────────────────────────────────────────────────────┘   ║
║  │        │                                                                     ║
║  │        │  Note admin (optionnelle) :                                         ║
║  │        │  ┌──────────────────────────────────────────────────────────────┐   ║  TextInput note
║  │        │  │ Bon profil · zone prometteuse · contrat en cours de signature│   ║  Inter 13sp
║  │        │  └──────────────────────────────────────────────────────────────┘   ║
║  │        │                                                                     ║
║  │        │  [  Annuler candidature  ]              [  ✓ Certifier Moussa  ]    ║
║  │        │  bg neutral-100 · color neutral-700    bg success-600 color-white   ║
║  │        │  Inter 14sp 500                        Inter 14sp 600               ║
║  └────────┘                                                                     ║
╚══════════════════════════════════════════════════════════════════════════════════╝

CertificationChecklist :
  Admin coche chaque item après vérification manuelle
  CTA "Certifier" actif seulement quand toutes les cases = ✓
  (sauf si Carlos override manuellement)

Après certification :
  → statut = "certifié" · accès back-office intégrateur activé
  → push FCM Moussa : "🎉 Certification Scalario validée — vous pouvez déployer vos premiers clients"
  → Moussa peut créer tenants via S17

Audit trail :
  certified_by = "carlos_s" · certified_at = timestamp · note = (note saisie)
```

---

## Annotations — Gestion Intégrateurs

### KPICard Time-to-Value

```
T2V < 1h  → bg success-50  · val success-700 · "✓ < 1h"  (SLA excellent)
T2V 1h-2h → bg warning-50  · val warning-700 · "⚠ ~Xh" (amélioration suggérée)
T2V > 2h  → bg danger-50   · val danger-700  · "⛔ ~Xh" (sous SLA)

Calcul : avg(temps entre création tenant → première connexion OWNER)
```

### Modèle Rémunération (affiché dans le détail)

```
MRR client 40 000 FCFA :
  → Kofi reçoit 24 000 FCFA (60%)
  → Scalario reçoit 16 000 FCFA (40%)
  Affiché : Roboto Mono · précis à 1 FCFA
```
