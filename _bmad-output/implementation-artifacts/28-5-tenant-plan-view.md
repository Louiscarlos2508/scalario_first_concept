# Story 28.5 — Frontend backoffice — Écran "Mon abonnement" dans Paramètres (FR102)

## Metadata

- **Epic:** Epic 28 — Plans Tarifaires & Facturation
- **Story ID:** 28-5-tenant-plan-view
- **Status:** backlog
- **Priority:** Medium
- **Phase:** 2a — self-service préparé pour Phase 3
- **Depends on:** 28-3 (GET /settings/billing + POST /settings/billing/upgrade-request), Epic 19 (backoffice settings)

---

## Story

**As a** tenant owner,
**I want** a "Mon abonnement" screen in my backoffice Settings that shows my current plan, included modules, billing status, and payment history, with a button to request an upgrade,
**So that** I can understand what I'm paying for and escalate upgrades without contacting Carlos directly (FR102).

---

## Acceptance Criteria

### AC1 — Écran "Mon abonnement" accessible depuis les Paramètres

**Given** le propriétaire est sur l'écran Paramètres du backoffice
**When** il tape sur "Mon abonnement"
**Then** l'écran `SubscriptionScreen` s'ouvre avec :
- Nom du plan actuel (badge coloré)
- Prix mensuel formaté FCFA
- `maxUsers` inclus
- Liste des modules inclus (icône + nom lisible en français)
- Statut de facturation (badge coloré)
- Prochaine échéance estimée (si `billingStartDate` défini : `billingStartDate + 30 jours`)

### AC2 — Historique des paiements

**Given** le propriétaire est sur l'écran "Mon abonnement"
**When** la section "Historique" est affichée
**Then** la liste des `BillingEvent` du tenant est affichée (type lisible, montant FCFA, date, statut)
**And** les événements `pending` affichent "En attente de paiement" en orange
**And** les événements `paid` affichent la date de paiement en vert
**And** si aucun événement, un message "Aucun historique de paiement" est affiché

### AC3 — Bouton "Demander un upgrade"

**Given** le propriétaire est sur "Mon abonnement"
**When** il tape "Demander un upgrade"
**Then** un dialog s'affiche avec un champ texte optionnel "Message pour l'administrateur"
**When** il confirme
**Then** `POST /api/v1/settings/billing/upgrade-request` est appelé avec `{ message? }`
**And** le propriétaire voit un `SnackBar` : "Votre demande a été envoyée. Carlos vous contactera sous 24h."
**And** le bouton est désactivé pendant 24h (état persisté localement)

### AC4 — Routes backend settings/billing

**Given** un propriétaire authentifié appelle `GET /api/v1/settings/billing`
**When** la requête est valide
**Then** la réponse est `200 OK` avec `{ plan: PlanDefinition, billingStatus, trialEndsAt, billingStartDate, events: BillingEvent[] }`
**And** seuls les événements du tenant de l'utilisateur sont retournés
**And** seul le rôle `Owner` peut accéder à cette route (`403` pour Manager et Commercial)

**Given** un propriétaire envoie `POST /api/v1/settings/billing/upgrade-request` avec `{ message? }`
**When** la requête est valide
**Then** une notification interne est créée à destination du superadmin
**And** la réponse est `201 Created` : `{ message: "Demande envoyée" }`

### AC5 — Écran bloquant si tenant suspendu

**Given** le tenant a `billingStatus = "suspended"`
**When** le propriétaire (ou tout utilisateur du tenant) ouvre l'application
**Then** l'écran `SuspendedScreen` s'affiche à la place du contenu normal :
- Titre : "Abonnement expiré"
- Message : "Votre abonnement Scalario est suspendu. Contactez votre administrateur pour régulariser votre situation."
- Bouton "Contacter" : ouvre `tel:<notificationPhone>` si renseigné, sinon `mailto:support@scalario.app`
**And** toute navigation vers un autre écran est bloquée (le router redirige systématiquement vers `SuspendedScreen`)

---

## Tasks / Subtasks

- [ ] **Task 1 — Routes backend settings/billing** (AC4)
  - [ ] Dans `BillingEventsController`, ajouter deux routes protégées par `JwtAuthGuard` + `TenantGuard` + rôle `Owner` :
    - `GET /settings/billing` → appelle `billingEventsService.getOwnerBilling(tenantId)`
    - `POST /settings/billing/upgrade-request` → crée une notification interne au superadmin
  - [ ] Whitelister ces routes dans `BillingGuard` (28-6) pour qu'elles restent accessibles si suspendu

- [ ] **Task 2 — SubscriptionRepository Flutter** (AC1–AC3)
  - [ ] Créer `apps/frontend/lib/features/shared/billing/data/repositories/subscription_repository.dart`
    - `getMySubscription()` → `GET /settings/billing`
    - `requestUpgrade({ String? message })` → `POST /settings/billing/upgrade-request`

- [ ] **Task 3 — Providers Riverpod** (AC1–AC3)
  - [ ] Créer `apps/frontend/lib/features/shared/billing/presentation/providers/subscription_provider.dart`
    - `subscriptionProvider` : `FutureProvider` — charge plan + events du tenant courant
    - `upgradeRequestedProvider` : `StateProvider<bool>` — état local "demande envoyée" (persisté 24h via SharedPreferences)

- [ ] **Task 4 — SubscriptionScreen** (AC1, AC2, AC3)
  - [ ] Créer `apps/frontend/lib/features/shared/billing/presentation/screens/subscription_screen.dart`
    - `PlanInfoCard` : plan, prix, maxUsers, modules inclus (noms lisibles)
    - Section statut + dates
    - `BillingHistoryList` : liste des BillingEvent
    - Bouton "Demander un upgrade" (désactivé si `upgradeRequestedProvider = true`)
  - [ ] Créer `apps/frontend/lib/features/shared/billing/presentation/widgets/plan_info_card.dart`
  - [ ] Créer `apps/frontend/lib/features/shared/billing/presentation/widgets/billing_history_list.dart`

- [ ] **Task 5 — SuspendedScreen** (AC5)
  - [ ] Créer `apps/frontend/lib/features/shared/billing/presentation/screens/suspended_screen.dart`
    - `WillPopScope` : intercepte le retour arrière
    - `url_launcher` : bouton "Contacter" → `tel:` ou `mailto:`
  - [ ] Intégrer dans le router principal : si `billingStatus = "suspended"`, rediriger vers `SuspendedScreen` depuis le guard de navigation (vérifier à l'initialisation de session et à chaque deep-link)

- [ ] **Task 6 — Lien dans Settings** (AC1)
  - [ ] Localiser l'écran Paramètres du backoffice
  - [ ] Ajouter une entrée "Mon abonnement" avec navigation vers `SubscriptionScreen`

- [ ] **Task 7 — Noms lisibles des modules** (AC1)
  - [ ] Créer un map `moduleCodeToLabel`:
    ```dart
    const moduleCodeToLabel = {
      'catalog': 'Catalogue',
      'inventory': 'Inventaire',
      'retail': 'Point de vente',
      'reporting': 'Rapports',
      'purchase_orders': 'Commandes fournisseurs',
      'variants': 'Variantes',
      'pricing': 'Multi-tarifs',
      'promotions': 'Promotions',
      'returns': 'Retours',
      'reservations': 'Réservations',
    };
    ```

---

## Files to Create

- `apps/frontend/lib/features/shared/billing/data/repositories/subscription_repository.dart`
- `apps/frontend/lib/features/shared/billing/presentation/providers/subscription_provider.dart`
- `apps/frontend/lib/features/shared/billing/presentation/screens/subscription_screen.dart`
- `apps/frontend/lib/features/shared/billing/presentation/screens/suspended_screen.dart`
- `apps/frontend/lib/features/shared/billing/presentation/widgets/plan_info_card.dart`
- `apps/frontend/lib/features/shared/billing/presentation/widgets/billing_history_list.dart`

## Files to Modify

- `apps/backend/src/kernel/billing/billing-events/billing-events.controller.ts` — routes `GET/POST /settings/billing`
- `apps/frontend/lib/features/retail/backoffice/presentation/screens/settings_screen.dart` — lien "Mon abonnement"
- Router principal Flutter — guard `billingStatus = "suspended"` → `SuspendedScreen`

---

## Dev Notes

### Notification upgrade-request

En Phase 2a, "notification interne" = log en base ou simple email. Implémenter comme un `BillingEvent` de type `"upgrade_request"` avec `status: "pending"` et `description: message`. Pas de notification push complexe en Phase 2a.

### Détection suspension au démarrage

Au login ou à la restauration de session, charger `GET /settings/billing` et vérifier `billingStatus`. Si `"suspended"`, stocker dans un `StateProvider<bool> isSuspendedProvider` et rediriger. Le `BillingGuard` backend (28-6) interceptera de toute façon les appels, mais l'UX doit bloquer avant même l'appel API.

### url_launcher

```yaml
# pubspec.yaml
url_launcher: ^6.x
```

```dart
launchUrl(Uri.parse('tel:+22670000000'));
```

### References

- [Source: _bmad-output/planning-artifacts/prd.md — FR102]
- [Source: _bmad-output/planning-artifacts/epics.md — Story 28-5]
- [Source: apps/frontend/lib/features/retail/backoffice/ — structure backoffice]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
