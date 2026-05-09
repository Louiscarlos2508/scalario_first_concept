---
type: components
group: inputs
components: [TextInput, NumberInput, QuantityControl, TimePicker, DatePicker, Toggle, FormWidget, ExpandableSection]
---

# Composants — Inputs

> Ces composants collectent des données de l'utilisateur.
> Tous validés en temps réel. Jamais de reset en cas d'erreur.

---

## TextInput

**Rôle :** Saisie de texte libre — nom, note, téléphone, etc.
**Règle :** Label toujours au-dessus. Hint en dessous si besoin. Erreur en rouge sous le champ.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `label` | string | Label visible au-dessus |
| `hint` | string? | Texte placeholder |
| `required` | bool | Affiche `*` sur le label |
| `type` | enum | `text` / `phone` / `email` / `multiline` |
| `max_length` | int? | Limite caractères |
| `validation_rule` | string? | Regex ou règle backend |

### Sketches ASCII

```
REPOS :
  Prénom *
  ┌────────────────────────────────────────┐
  │                                        │
  └────────────────────────────────────────┘
  _Prénom de l'employé_

FOCUS :
  Prénom *
  ┌────────────────────────────────────────┐  ← bordure color-primary-500
  │ Ibrahim|                               │
  └────────────────────────────────────────┘

REMPLI :
  Prénom *
  ┌────────────────────────────────────────┐
  │ Ibrahim                                │
  └────────────────────────────────────────┘

ERREUR :
  Téléphone *
  ┌────────────────────────────────────────┐  ← bordure color-danger-500
  │ 0708                                   │
  └────────────────────────────────────────┘
  _[✕] Numéro invalide — format attendu : +225 XX XX XX XX_

MULTILINE :
  Note (optionnel)
  ┌────────────────────────────────────────┐
  │ Les tomates étaient déjà abîmées à     │
  │ la livraison — voir photos.            │
  │                                        │
  └────────────────────────────────────────┘
                              _42 / 200 car._
```

---

## NumberInput

**Rôle :** Saisie d'un nombre avec contraintes (seuil, quantité entière, prix).
**Règle :** Clavier numérique auto-ouvert. Unité affichée à droite.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `label` | string | Label |
| `unit` | string | Unité (kg, FCFA, articles) |
| `min` | number? | Valeur minimum |
| `max` | number? | Valeur maximum |
| `decimal` | bool | Autorise décimales |

### Sketch ASCII

```
  Seuil stock critique *                  (unité: kg)
  ┌────────────────────────────────┬──────┐
  │  5                             │  kg  │
  └────────────────────────────────┴──────┘
  _Alerte déclenchée quand le stock descend sous ce seuil_

  ERREUR (valeur hors limites) :
  ┌────────────────────────────────┬──────┐  ← rouge
  │  0                             │  kg  │
  └────────────────────────────────┴──────┘
  _[✕] La valeur minimum est 0,1 kg_
```

---

## QuantityControl

**Rôle :** Saisie de quantité avec boutons +/− pour ajustement rapide.
**Variantes :** Vrac (décimal, unité kg) / Unit (entier, unité pièce/article).

### Props

| Prop | Type | Description |
|------|------|-------------|
| `pos_type` | enum | `vrac` / `unit` — détermine clavier et unité |
| `unit` | string | Unité affichée (kg, pièce, litre…) |
| `step` | number | Incrément (0.1 pour vrac, 1 pour unit) |
| `min` | number | 0 par défaut |
| `max` | number? | Stock disponible (si POS) |

### Sketches ASCII

```
VRAC (décimal — clavier décimal) :
  ┌──────┐  ┌──────────────────┐  ┌──────┐
  │  −   │  │     4,5 kg       │  │  +   │
  └──────┘  └──────────────────┘  └──────┘
  boutons: color-primary-500 | valeur: text-body-medium

UNIT (entier — clavier numérique) :
  ┌──────┐  ┌──────────────────┐  ┌──────┐
  │  −   │  │    12 pièces     │  │  +   │
  └──────┘  └──────────────────┘  └──────┘

MAXIMUM ATTEINT (bouton + désactivé) :
  ┌──────┐  ┌──────────────────┐  ┌──────┐
  │  −   │  │   20 kg (max)    │  │  ░   │  ← + grisé
  └──────┘  └──────────────────┘  └──────┘
  _Stock disponible : 20 kg_

ZÉRO :
  ┌──────┐  ┌──────────────────┐  ┌──────┐
  │  ░   │  │     0 kg         │  │  +   │  ← − grisé
  └──────┘  └──────────────────┘  └──────┘
```

---

## TimePicker

**Rôle :** Sélection d'une heure (HH:MM, format 24h).
**Usage :** Heure d'envoi alerte (S13), heure de clôture configurable.

### Sketch ASCII

```
  Heure d'envoi *
  ┌─────────────┐
  │   19 : 30   │  ← tap → wheel picker natif Android/Flutter
  └─────────────┘
  _Résumé soir envoyé à cette heure_
```

---

## DatePicker

**Rôle :** Sélection d'une date (JJ/MM/AAAA).
**Usage :** Échéance crédit (S15), date livraison souhaitée (S16).

### Sketch ASCII

```
  Échéance remboursement *
  ┌─────────────────────┐
  │  15 / 05 / 2026     │  ← tap → calendar picker
  └─────────────────────┘
  _Date à laquelle le solde doit être remboursé_
```

---

## Toggle

**Rôle :** Activation / désactivation d'une option booléenne.
**Usage :** Alerte active/inactive (S13), silence nocturne (S13), biométrie (S10).

### Props

| Prop | Type | Description |
|------|------|-------------|
| `label` | string | Label à gauche du toggle |
| `description` | string? | Caption explicative sous le label |
| `value` | bool | État actuel |

### Sketch ASCII

```
ACTIF :
  Alerte stock critique          [●────]
  _Notifie quand un article passe sous le seuil_

INACTIF :
  Résumé soir                    [────○]
  _Désactivé — tu ne recevras pas de résumé quotidien_

SILENCE NOCTURNE :
  Silence nocturne               [●────]
  _Pas d'alertes entre 22:00 et 07:00_
```

---

## FormWidget

**Rôle :** Conteneur de formulaire — wraps tous les champs de saisie d'un écran. Gère le scroll, l'évitement du clavier, l'état de validation global et l'activation du CTA.
**Usage :** S06.2, S09.2, S10.2, S11.2, S13.2, S15.2, S16.2, S17.1, S17.2, S23.1, S25.2, S26.1 — présent dans tout écran avec des champs de saisie.
**Règle :** Le CTA principal (ActionButton) est toujours à l'intérieur du FormWidget, en position sticky-bottom. Le FormWidget expose un état `is_valid: bool` qui active ou désactive le CTA.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `fields` | list | Composants enfants (TextInput, NumberInput, ChipSelector…) |
| `cta_label` | string | Label du bouton de soumission |
| `cta_route` | string | Route de destination si validation OK |
| `on_submit` | callback | Action déclenchée à la soumission |
| `scroll` | bool | true = SingleChildScrollView (défaut: true) |
| `keyboard_avoid` | bool | true = resizeToAvoidBottomInset (défaut: true) |

### Sketch ASCII

```
FORMULAIRE EMPLOYÉ (S10.2) :
┌──────────────────────────────────────────────┐
│ ← AJOUTER UN EMPLOYÉ                        │  AppBar
├──────────────────────────────────────────────┤
│  [scroll zone — FormWidget body]             │
│                                              │
│  Prénom *                                    │
│  ┌──────────────────────────────────────┐   │
│  │ Ibrahim                              │   │  TextInput
│  └──────────────────────────────────────┘   │
│                                              │
│  Téléphone *                                 │
│  ┌──────────────────────────────────────┐   │
│  │ +225 07 89 12 34                     │   │  TextInput type=phone
│  └──────────────────────────────────────┘   │
│                                              │
│  Rôle *                                      │
│  [● Commercial]  [○ Manager]                 │  ChipSelector
│                                              │
│  [... autres champs ...]                     │
│                                              │
├──────────────────────────────────────────────┤  ← sticky-bottom (dans FormWidget)
│  [████████████ Créer l'employé █████████████]│  ActionButton · activé si is_valid
└──────────────────────────────────────────────┘

CTA DÉSACTIVÉ (champs invalides) :
│  [░░░░░░░░░░░░ Créer l'employé ░░░░░░░░░░░░]│  bg color-neutral-200
```

---

## ExpandableSection

**Rôle :** Section de formulaire repliable — masquée par défaut, s'ouvre au tap du titre. Utilisé pour les champs optionnels ou rarement modifiés (changement MDP, options avancées).
**Usage :** S25.2 (Edit profil — section changement MDP), S17.2 (config avancée tenant).
**Règle :** Titre toujours visible. Animation expand/collapse 200ms ease-in-out. Jamais de champ required dans une ExpandableSection (risque de soumission avec champ caché invalide).

### Props

| Prop | Type | Description |
|------|------|-------------|
| `title` | string | Label du titre cliquable |
| `initially_expanded` | bool | false = replié par défaut |
| `children` | list | Champs internes |

### Sketch ASCII

```
REPLIÉ (défaut) :
  ┌──────────────────────────────────────────┐
  │ Changer le mot de passe              [+] │  ← tap pour ouvrir
  └──────────────────────────────────────────┘
  Inter 13sp 600 neutral-700 · icône [+] primary-500

OUVERT :
  ┌──────────────────────────────────────────┐
  │ Changer le mot de passe              [−] │  ← tap pour refermer
  │  ─────────────────────────────────────   │  séparateur
  │  Mot de passe actuel *                   │
  │  ┌──────────────────────────────────┐   │  TextInput obscureText
  │  │ ●●●●●●●●                    [👁] │   │
  │  └──────────────────────────────────┘   │
  │                                          │
  │  Nouveau mot de passe *                  │
  │  ┌──────────────────────────────────┐   │
  │  │ ●●●●●●●●●●●●            [👁]    │   │
  │  └──────────────────────────────────┘   │
  │  [PasswordStrengthBar]                   │
  └──────────────────────────────────────────┘
```
