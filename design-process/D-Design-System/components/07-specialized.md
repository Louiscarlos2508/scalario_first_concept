---
type: components
group: specialized
components: [PaymentConfirm, AlertPreview, CredentialsCard, OnboardingCard, EmptyState, LoginWidget, TemplateSelector, AvatarCard, POSPreview]
---

# Composants — Spécialisés

> Composants à usage ciblé — un seul scénario ou contexte précis.

---

## PaymentConfirm

**Rôle :** Récapitulatif final avant validation d'une vente — affiche tout ce qui sera enregistré.
**Usage :** S02.3 (Confirmation Paiement), S15.3 (Confirmation Crédit).

### Sketch ASCII

```
VENTE STANDARD :
╔══════════════════════════════════════════╗
║  Récapitulatif vente                     ║
║  ─────────────────────────────────────   ║
║  Tomates              2,5 kg  3 750 FCFA ║
║  Igname               5 kg    4 000 FCFA ║
║  Poivrons             1 kg    2 000 FCFA ║
║  ─────────────────────────────────────   ║
║  TOTAL                        9 750 FCFA ║
║  ─────────────────────────────────────   ║
║  Mode paiement : [● Espèces]             ║
╚══════════════════════════════════════════╝
┌────────────────────────────────────────┐
│ ████████████ Confirmer la vente ███████│
└────────────────────────────────────────┘

VENTE CRÉDIT :
╔══════════════════════════════════════════╗
║  Récapitulatif vente crédit              ║
║  ─────────────────────────────────────   ║
║  Tomates 2,5kg · Igname 5kg             ║
║  ─────────────────────────────────────   ║
║  Total              15 000 FCFA          ║
║  Versé maintenant    5 000 FCFA          ║
║  Solde dû           10 000 FCFA [! Crédit]║
║  ─────────────────────────────────────   ║
║  Client : Mamadou Koné                   ║
║  Échéance : 15/05/2026                   ║
╚══════════════════════════════════════════╝
┌────────────────────────────────────────┐
│ ████████ Confirmer vente crédit ███████│
└────────────────────────────────────────┘
```

---

## AlertPreview

**Rôle :** Prévisualisation en temps réel du résultat d'une configuration.
**Usage :** S13.2 (Config Alerte), S15.2 (Paiement Partiel — récap solde).
**Règle :** Se met à jour à chaque saisie (debounce 300ms). Toujours visible sans scroll.

### Sketch ASCII

```
CONFIG ALERTE :
╔══════════════════════════════════════════╗
║  Aperçu de ton alerte                    ║
║                                          ║
║  "Tu recevras une notification push      ║
║   quand le stock de Tomates descend      ║
║   sous 5 kg — entre 07:00 et 22:00."     ║
╚══════════════════════════════════════════╝
bg: color-primary-50 | texte: text-body | radius-lg

RÉCAP CRÉDIT :
╔══════════════════════════════════════════╗
║  Solde dû : 10 000 FCFA                  ║
║  Échéance : 15 mai 2026                  ║
║  Client   : Mamadou Koné                 ║
╚══════════════════════════════════════════╝
bg: color-warning-100 | bordure gauche: color-warning-500
```

---

## CredentialsCard

**Rôle :** Affiche les identifiants générés pour un nouvel utilisateur — copyable + partage WhatsApp.
**Usage :** S10.3 (Confirmation employé), S17.3 (Confirmation déploiement).
**Règle Sécurité :** Mot de passe affiché une seule fois. Message explicite "Notez-le maintenant".

### Sketch ASCII

```
╔══════════════════════════════════════════╗
║  Identifiants de connexion               ║
║  ─────────────────────────────────────   ║
║  Nom d'utilisateur                       ║
║  ┌────────────────────────────────────┐  ║
║  │ 0708123456                    [📋] │  ║  ← copy
║  └────────────────────────────────────┘  ║
║                                          ║
║  Mot de passe temporaire                 ║
║  ┌────────────────────────────────────┐  ║
║  │ Sc@2026!Ibrahim               [📋] │  ║
║  └────────────────────────────────────┘  ║
║  _⚠ Notez ce mot de passe maintenant._   ║
║  _Il ne sera plus affiché après cette_   ║
║  _page._                                 ║
║  ─────────────────────────────────────   ║
║  [  Envoyer par WhatsApp  ]              ║
╚══════════════════════════════════════════╝
```

---

## OnboardingCard

**Rôle :** Message de bienvenue affiché uniquement à la première connexion.
**Usage :** S07.2 (Dashboard First Run).
**Règle :** Dismissable par tap n'importe où. Ne réapparaît jamais.

### Sketch ASCII

```
╔══════════════════════════════════════════╗
║  Bienvenue sur Scalario 👋               ║
║                                          ║
║  Voici votre espace de travail.          ║
║  Tapez "Nouvelle vente" pour commencer.  ║
║                                          ║
║                      [Compris, merci !]  ║
╚══════════════════════════════════════════╝
Tap anywhere = dismiss | bg: color-primary-50
```

---

## EmptyState

**Rôle :** Illustration et message quand une liste est vide — guide vers l'action.
**Usage :** S07.2 (nouveau tenant sans données), toute liste vide.

### Sketch ASCII

```
┌──────────────────────────────────────────────┐
│                                              │
│              [  illustration  ]              │
│                                              │
│        Aucune vente aujourd'hui              │
│                                              │
│   _Tapez sur "Nouvelle vente" pour          _│
│   _enregistrer votre première transaction._ │
│                                              │
│   ┌────────────────────────────────────┐    │
│   │ ████████ Nouvelle vente ████████████│    │
│   └────────────────────────────────────┘    │
└──────────────────────────────────────────────┘
```

---

## LoginWidget

**Rôle :** Formulaire de connexion — première authentification (username + mot de passe).
**Usage :** S07.1 (App Launch Login).
**Note :** Re-auth rapide (biométrie/PIN) est gérée par le système — pas un composant Scalario.

### Sketch ASCII

```
┌──────────────────────────────────────────────┐
│               [Logo Scalario]                │
│                                              │
│  Nom d'utilisateur ou téléphone              │
│  ┌──────────────────────────────────────┐   │
│  │ 0708123456                           │   │
│  └──────────────────────────────────────┘   │
│                                              │
│  Mot de passe                                │
│  ┌──────────────────────────────────────┐   │
│  │ ●●●●●●●●                        [👁] │   │
│  └──────────────────────────────────────┘   │
│                                              │
│  ┌──────────────────────────────────────┐   │
│  │ ██████████ Se connecter █████████████│   │
│  └──────────────────────────────────────┘   │
│                                              │
│              _Mot de passe oublié ?_         │
│                                              │
│  [ProfileLoader en cours...]                 │  ← après submit
└──────────────────────────────────────────────┘

ERREUR :
┌──────────────────────────────────────────────┐
│ [✕] Identifiants incorrects. Réessaie.       │
└──────────────────────────────────────────────┘
```

---

## TemplateSelector

**Rôle :** Sélection du template métier lors de la création d'un tenant (back-office Kofi).
**Usage :** S17.1 (Création Tenant).

### Sketch ASCII

```
Choisir un template *
┌──────────────────────────────────────────────┐
│ ●  Retail Fresh Produce                      │
│    _Commerce alimentaire frais — légumes,_   │
│    _fruits, produits de marché_              │
│    Modules : POS · Stock · Alertes · Rapports│
├──────────────────────────────────────────────┤
│ ○  Épicerie Générale                         │
│    _Vente au détail — produits secs,_        │
│    _emballés, boissons_          [Bientôt]  │
├──────────────────────────────────────────────┤
│ ○  Restaurant / Snack                        │
│    _Service de restauration_     [Bientôt]  │
└──────────────────────────────────────────────┘
_Seul "Retail Fresh Produce" est disponible pour Gate 0_
```

---

## AvatarCard

**Rôle :** Affichage de l'avatar utilisateur — initiales sur fond coloré (pas de photo). Accompagné du nom, du rôle et du nom du magasin.
**Usage :** S25.1 (Vue profil utilisateur).
**Règle :** Jamais de photo — initiales uniquement (2 premières lettres prénom+nom). Taille 64px sur mobile, 80px sur web.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `initials` | string | 2 lettres (ex: "BK" pour Blandine Kouamé) |
| `name` | string | Nom complet |
| `role` | enum | `owner` / `commercial` / `manager` |
| `tenant_name` | string | Nom du magasin |
| `size` | enum | `md` (64px mobile) / `lg` (80px web) |

### Tokens

| Élément | Token | Valeur |
|---------|-------|--------|
| Fond avatar | `color-primary-500` | #FFCC00 |
| Initiales | `color-neutral-900` | Inter 24sp 700 |
| Diamètre mobile | — | 64px · radius-full |
| Diamètre web | — | 80px · radius-full |
| Nom | `text-title` | Inter 18sp 700 neutral-900 |
| Rôle badge | `text-caption` | Inter 12sp 500 neutral-500 |

### Sketch ASCII

```
MOBILE (S25.1) :
┌──────────────────────────────────────────────┐
│           ╔══════════╗                       │
│           ║    BK    ║  ← 64px radius-full   │
│           ╚══════════╝  bg color-primary-500  │
│                                              │
│         Blandine Kouamé                      │  Inter 18sp 700
│         PROPRIÉTAIRE                         │  Inter 12sp 500 neutral-500
│         Boutique Kouamé                      │  Inter 13sp 400 neutral-600
└──────────────────────────────────────────────┘
centré · padding-top 24px
```

---

## POSPreview

**Rôle :** Aperçu compact de l'état courant du POS — session active, fond de caisse, nombre de ventes du jour. Affiché sur le Dashboard COMMERCIAL pour donner le contexte avant d'ouvrir le POS.
**Usage :** S21.1 (Dashboard Commercial — bloc session).
**Règle :** Tappable → ouvre directement le POS (S02). Affiché seulement si une session caisse est active.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `session_status` | enum | `active` / `none` |
| `ventes_count` | int | Nb ventes du jour |
| `ca_today` | number | CA encaissé du jour (FCFA) |
| `fond_ouverture` | number | Fond déclaré à l'ouverture |
| `opened_at` | datetime | Heure d'ouverture session |

### Sketch ASCII

```
SESSION ACTIVE :
┌──────────────────────────────────────────────┐
│ 🟢 Session ouverte depuis 08h15              │  bg color-success-50
│ Fond de caisse : 15 000 FCFA                 │  Roboto Mono
│ Mes ventes : 7  ·  CA : 42 500 FCFA          │  Roboto Mono
│                                              │
│ [████████████ Nouvelle vente ███████████████]│  → POS direct
└──────────────────────────────────────────────┘

AUCUNE SESSION (matin avant ouverture) :
┌──────────────────────────────────────────────┐
│ ○ Aucune session active                      │  bg color-warning-50
│ _Ouvrez la caisse avant de vendre_           │
│ [████████████ Ouvrir la caisse █████████████]│  → S26.1
└──────────────────────────────────────────────┘
```
