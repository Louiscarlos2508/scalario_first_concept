---
type: ux-rules
slug: patterns
---

# UX Rules — Patterns d'Interaction

---

## Pattern 1 — Flow Formulaire Standard

**Applicable à :** S03, S05, S06, S09, S10, S11, S13, S15, S16, S17

```
[Dashboard] → [Formulaire] → [ConfirmationDialog?] → [AlertBanner vert 2s] → [Dashboard]
```

**Règles :**
- Champs obligatoires marqués d'un `*`
- Validation en temps réel (pas seulement au submit)
- `ActionButton` submit désactivé si champs obligatoires vides
- Après submit : `AlertBanner` vert éphémère (2 secondes) puis retour automatique
- Erreur réseau : message d'erreur sous le bouton, données saisies conservées
- Pas de reset du formulaire en cas d'erreur

---

## Pattern 2 — Flow POS (Point de Vente)

**Applicable à :** S02, S15

```
[Dashboard] → [ProductSelector] → [QuantityControl] → [PaymentMode] → [PaymentConfirm] → [AlertBanner vert]
```

**Règles :**
- ProductSelector : articles triés par fréquence de vente décroissante
- QuantityControl : clavier numérique auto-focus à l'ouverture
- Vrac (kg) : clavier décimal — Unit (pièce) : clavier entier
- Montant total mis à jour en temps réel à chaque saisie
- Mode paiement : ChipSelector — sélection rapide, pas de scroll
- Confirmation : récap lisible en 5 secondes — tap confirmer
- Offline : flow identique, transaction en queue Drift

---

## Pattern 3 — Notification Push → App

**Applicable à :** S04, S06 (notification Blandine), S15, S16

```
[Push FCM] → [Deep link] → [Vue alerte / contexte] → [Action ou dismiss]
```

**Règles :**
- La notification affiche : qui / quoi / montant ou quantité
- Le deep link ouvre directement la vue contextuelle (pas le dashboard)
- La vue contextuelle a l'`AlertBanner` active en haut
- L'action est disponible directement depuis cette vue
- Si l'app est fermée : même comportement que si ouverte

**Format notifications push :**
- Clôture : "Clôture caisse [Commercial] — [montant] FCFA"
- Stock critique : "Stock critique : [article] — [quantité] restante"
- Perte : "Perte déclarée : [article] [quantité] — [motif]"
- Vente crédit : "Vente crédit [Commercial] — [client] — [solde] FCFA"
- Inventaire écart : "Inventaire — [X] écarts détectés"

---

## Pattern 4 — Action Destructive

**Applicable à :** S14 (annulation vente), S10 (désactivation employé), A02 (suspension tenant)

```
[ActionButton rouge/ambre] → [ConfirmationDialog] → [Exécution] → [AlertBanner vert]
```

**ConfirmationDialog structure :**
```
╔══════════════════════════════════════════╗
║  Confirmer l'annulation ?                ║
║                                          ║
║  Annuler la vente de 12 500 FCFA.        ║
║  Le stock sera remis à jour.             ║
║  Cette action est irréversible.          ║
║                                          ║
║  [   Annuler   ]  [ Confirmer annulation ]║
║   ← toujours à gauche   → rouge, droite ║
╚══════════════════════════════════════════╝
```

---

## Pattern 5 — Liste + Détail

**Applicable à :** S12 (rapports), S14 (historique ventes), S19 (historique stock), A02 (tenants)

```
[Liste filtrée] → [Tap item] → [Détail item] → [Action ou retour liste]
```

**Règles :**
- La liste a toujours des `FilterChips` visibles sans scroll
- Le tri par défaut est chronologique décroissant (plus récent en premier)
- Le détail a un bouton retour en haut à gauche
- Sur Flutter Web : liste à gauche, détail à droite (split view)
- Sur mobile : navigation push (détail remplace la liste)

---

## Pattern 6 — Dashboard → Drill-down

**Applicable à :** S12, S19, S20

```
[KPICard tappable] → [Vue détail métrique] → [FilterChips] → [Compréhension]
```

**Règles :**
- Toutes les `KPICard` du dashboard OWNER sont tappables (curseur pointer sur web)
- L'indicateur de tappabilité : chevron `>` discret en bas à droite de la card
- La vue drill-down conserve le contexte (titre = métrique + période)
- Les `FilterChips` sont pré-remplis avec la sélection qui correspond au tap

---

## Pattern 7 — Onboarding First Run

**Applicable à :** S07

```
[Login] → [ProfileLoader] → [Dashboard avec OnboardingCard] → [Dismiss] → [Dashboard normal]
```

**Règles :**
- `OnboardingCard` visible seulement à la première ouverture
- Message : bref, actionnable — "Voici votre dashboard. Tapez pour commencer."
- Dismiss : tap n'importe où ou bouton "Compris"
- Pas de carousel ou tutorial multi-étapes — Gate 0 simplifié

---

## Pattern 8 — Offline Queue

**Applicable à :** S08 (et tous les flows offline)

```
[Action utilisateur] → [Drift local] → [Queue sync] → [Retour réseau] → [Sync silencieuse]
```

**Règles :**
- Toute action réussit immédiatement en local (Drift)
- La queue est invisible pour l'utilisateur — pas d'indicateur de "X actions en attente"
- Exception : si la queue dépasse 24h sans sync → `AlertBanner` ambre discrète
- La sync est silencieuse — pas de notification "sync réussie"
- Exception : si conflit détecté → notification admin Scalario uniquement (pas utilisateur)

---

## Pattern 9 — Formulaire avec Prévisualisation

**Applicable à :** S13 (AlertPreview), S15 (récap crédit)

```
[Saisie formulaire] → [Prévisualisation temps réel] → [Confirmation]
```

**Règles :**
- La prévisualisation se met à jour à chaque saisie (pas au submit)
- Format texte clair : "Tu recevras une alerte quand le stock de Tomates descend sous 5 kg"
- La prévisualisation est toujours visible sans scroll (above le bouton de confirmation)
- Style : texte Inter, fond légèrement coloré (color-primary-50), coin arrondi

---

## Pattern 10 — Calcul Temps Réel

**Applicable à :** S11 (marge), S15 (solde dû), S16 (montant estimé), S18 (écart inventaire)

**Règles :**
- Le calcul se déclenche à chaque keystroke — debounce 300ms
- La valeur calculée est dans une `KPICard` ou un badge — jamais dans un champ éditable
- Si le calcul donne un résultat anormal (marge négative, écart > 50%), badge rouge automatique
- Le calcul fonctionne offline (logique locale, pas d'appel API)
