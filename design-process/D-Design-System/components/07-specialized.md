---
type: components
group: specialized
components: [PaymentConfirm, AlertPreview, CredentialsCard, OnboardingCard, EmptyState, LoginWidget, TemplateSelector]
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
