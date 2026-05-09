# Story 28.6 — Backend + Frontend — Enforcement statut suspendu (FR101)

## Metadata

- **Epic:** Epic 28 — Plans Tarifaires & Facturation
- **Story ID:** 28-6-billing-status-enforcement
- **Status:** backlog
- **Priority:** High
- **Phase:** 2a
- **Depends on:** 28-3 (BillingEvent, billingStatus sur Tenant), 28-5 (SuspendedScreen)

---

## Story

**As a** system,
**I want** that all API endpoints return 403 when a tenant is suspended, and the Flutter client intercepts this code to display a blocking expiry screen,
**So that** suspended tenants cannot use the app until their subscription is regularised (FR101).

---

## Acceptance Criteria

### AC1 — BillingGuard backend — blocage global

**Given** un utilisateur d'un tenant avec `billingStatus = "suspended"` envoie une requête authentifiée
**When** la requête atteint n'importe quel endpoint sauf la whitelist
**Then** le backend répond `403 Forbidden` avec :
```json
{ "error": "TENANT_SUSPENDED", "message": "Abonnement expiré — contactez votre administrateur" }
```

### AC2 — Tenants non suspendus non affectés

**Given** un utilisateur d'un tenant avec `billingStatus ∈ { "trial", "active", "overdue" }`
**When** il envoie une requête normale
**Then** le `BillingGuard` laisse passer sans overhead perceptible (lecture depuis cache mémoire TTL 60s)
**And** uniquement `billingStatus = "suspended"` bloque l'accès

### AC3 — Whitelist routes exclues du guard

**Given** un utilisateur d'un tenant suspendu
**When** il appelle l'une des routes whitelistées :
- `POST /auth/login`
- `POST /auth/refresh`
- `GET /settings/billing`
**Then** le `BillingGuard` laisse passer la requête

### AC4 — Flutter — interception 403 TENANT_SUSPENDED

**Given** le client Flutter reçoit une réponse `403` avec `error: "TENANT_SUSPENDED"`
**When** l'intercepteur Dio détecte ce code d'erreur dans n'importe quel appel API
**Then** la navigation est redirigée vers `SuspendedScreen` (défini en 28-5)
**And** les appels API suivants dans la même session ne sont pas relancés inutilement

### AC5 — Réactivation par le superadmin

**Given** le superadmin appelle `PATCH /api/v1/admin/tenants/:id/billing` avec `{ billingStatus: "active" }`
**When** le tenant était `"suspended"`
**Then** `tenant.billingStatus` passe à `"active"`
**And** un `BillingEvent` `{ type: "payment", status: "paid", description: "Réactivation manuelle par superadmin" }` est créé
**And** le cache `billingStatus` pour ce tenant est invalidé immédiatement
**And** les prochaines requêtes du tenant ne sont plus bloquées

---

## Tasks / Subtasks

- [ ] **Task 1 — BillingGuard NestJS** (AC1, AC2, AC3)
  - [ ] Créer `apps/backend/src/kernel/billing/guards/billing.guard.ts`
    - Implémenter `CanActivate`
    - Lire `tenantId` depuis le contexte de requête (déjà peuplé par `TenantGuard`)
    - Cache en mémoire (`Map<string, { status: string, cachedAt: number }>`) TTL 60 secondes
    - Si `billingStatus = "suspended"` → throw `ForbiddenException({ error: 'TENANT_SUSPENDED', ... })`
    - Whitelist : vérifier `request.url` against `['/auth/login', '/auth/refresh', '/settings/billing']`
    - Si pas de `tenantId` dans le contexte (route publique) → laisser passer
  - [ ] Enregistrer `BillingGuard` comme `APP_GUARD` global dans `AppModule` après `JwtAuthGuard` et `TenantGuard`

- [ ] **Task 2 — Cache invalidation à la réactivation** (AC5)
  - [ ] Dans `BillingEventsService.updateBilling()` (28-3), invalider le cache du guard quand `billingStatus` change
  - [ ] Injecter `BillingGuard` (ou un `BillingCacheService` partagé) dans `BillingEventsService` pour appeler `invalidateCache(tenantId)`
  - [ ] Alternativement : exposer un `EventEmitter` interne que le guard écoute

- [ ] **Task 3 — Intercepteur Dio Flutter** (AC4)
  - [ ] Localiser `apps/frontend/lib/core/network/api_client.dart` (client Dio global)
  - [ ] Ajouter un `InterceptorsWrapper` :
    ```dart
    onError: (error, handler) {
      if (error.response?.statusCode == 403) {
        final body = error.response?.data;
        if (body is Map && body['error'] == 'TENANT_SUSPENDED') {
          // naviguer vers SuspendedScreen via navigatorKey global
          navigatorKey.currentState?.pushNamedAndRemoveUntil('/suspended', (_) => false);
          return;
        }
      }
      handler.next(error);
    }
    ```
  - [ ] Utiliser un `GlobalKey<NavigatorState>` partagé (vérifier si déjà présent dans le projet)

- [ ] **Task 4 — Tests backend** (AC1–AC3, AC5)
  - [ ] Test : tenant suspendu → 403 avec `error: "TENANT_SUSPENDED"` sur endpoint protégé
  - [ ] Test : tenant suspendu → `GET /settings/billing` → 200 (whitelist)
  - [ ] Test : tenant trial/active/overdue → pas de 403
  - [ ] Test : cache TTL → after 60s, relit le status depuis DB
  - [ ] Test : réactivation → cache invalidé → requête suivante passe

- [ ] **Task 5 — Test Flutter** (AC4)
  - [ ] Test widget : intercepteur déclenche navigation vers `SuspendedScreen` si 403 + TENANT_SUSPENDED
  - [ ] Test widget : 403 sans `TENANT_SUSPENDED` ne déclenche pas la redirection (erreur normale)

---

## Files to Create

- `apps/backend/src/kernel/billing/guards/billing.guard.ts`

## Files to Modify

- `apps/backend/src/app.module.ts` — `APP_GUARD` pour `BillingGuard` (après `JwtAuthGuard`)
- `apps/frontend/lib/core/network/api_client.dart` — intercepteur `403 TENANT_SUSPENDED`
- `apps/backend/src/kernel/billing/billing-events/billing-events.service.ts` — `reactivateTenant()` crée le BillingEvent + invalide cache

---

## Dev Notes

### Ordre des guards dans AppModule

L'ordre d'enregistrement des `APP_GUARD` détermine l'ordre d'exécution :
```typescript
providers: [
  { provide: APP_GUARD, useClass: JwtAuthGuard },   // 1er
  { provide: APP_GUARD, useClass: TenantGuard },    // 2e — peuple tenantId dans request
  { provide: APP_GUARD, useClass: BillingGuard },   // 3e — lit tenantId depuis request
]
```
`BillingGuard` doit être APRÈS `TenantGuard` pour avoir accès au `tenantId`.

### Cache en mémoire

```typescript
private cache = new Map<string, { status: string; cachedAt: number }>();
private TTL_MS = 60_000; // 60 secondes

async getStatus(tenantId: string): Promise<string> {
  const cached = this.cache.get(tenantId);
  if (cached && Date.now() - cached.cachedAt < this.TTL_MS) {
    return cached.status;
  }
  const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId }, select: { billingStatus: true } });
  const status = tenant?.billingStatus ?? 'active';
  this.cache.set(tenantId, { status, cachedAt: Date.now() });
  return status;
}

invalidate(tenantId: string): void {
  this.cache.delete(tenantId);
}
```

### NavigatorKey global Flutter

Si le projet n'a pas encore de `GlobalKey<NavigatorState>` global, l'ajouter dans `main.dart` :
```dart
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// puis dans MaterialApp : navigatorKey: navigatorKey
```

### Offline consideration

Le `BillingGuard` ne s'applique qu'aux requêtes API — il n'affecte pas les opérations offline-first (Isar local). Un tenant suspendu peut théoriquement continuer à écrire localement en mode offline, mais ses mutations ne seront pas synchronisées (le sync échouera avec 403). Ce comportement est acceptable en Phase 2a.

### References

- [Source: _bmad-output/planning-artifacts/prd.md — FR101]
- [Source: _bmad-output/planning-artifacts/epics.md — Story 28-6]
- [Source: apps/backend/src/app.module.ts — pattern APP_GUARD]
- [Source: apps/frontend/lib/core/network/api_client.dart — client Dio]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
