# Idempotency (STORY-036)

HTTP-level idempotency cache for POST endpoints. Prevents duplicate side
effects when the SyncQueueWorker (STORY-034) retries after network
flakes.

## Convention

Every POST under the allowlist requires the header:

```
X-Client-Mutation-Id: <uuid-v4>
```

This follows PRD §FR-059. We plan to also alias `Idempotency-Key`
(Stripe/Square convention) in Phase 2 for the public API.

## URL allowlist

- `POST /api/v1/{tenant}/sync/*`
- `POST /api/v1/{tenant}/{moduleId}/action`

Other POST endpoints (auth login, public webhooks) are not intercepted.

## Cache layout

- Backend: Redis (single instance, see [`cache/services/redis.service.ts`](../cache/services/redis.service.ts))
- Key shape: `idem:{tenant_id}:{client_mutation_id}` — scoped per
  tenant (read from the JWT, **not** the body) to prevent cross-tenant
  replay attacks.
- Value: `{ status, body, contentType, capturedAt, userId }` serialized
  as JSON.
- TTL: 24h (`86_400` seconds). Mobile clients online at least once per
  day in normal operation.

## Behaviour

| Scenario | Response |
|---|---|
| Missing header | `400 missing_idempotency_key` |
| Invalid format (non-UUID-v4, >128 chars) | `400 invalid_idempotency_key` |
| Cache MISS | controller runs, response cached (unless 5xx) |
| Cache HIT (same user) | cached body + header `X-Idempotency-Replay: true` |
| Cache HIT (different user, same tenant) | `409 idempotency_user_mismatch` |
| Cache collision (same key, different body) | first response is kept; collision logged |
| 5xx response | NOT cached (transient — let clients retry) |
| 4xx response | NOT cached at this layer (Nest exception filter runs first) |
| Redis down | fail-open; request proceeds, business layer prevents dupes via `sync_mutations` |

## Layering with the business-layer IdempotencyService

The existing
[`module-engine/services/idempotency.service.ts`](../module-engine/services/idempotency.service.ts)
is a Postgres-backed (`sync_mutations` table) check for action-level
idempotence. It still runs inside the controller. This HTTP interceptor
adds a faster outer layer that short-circuits before the controller is
even invoked. Both are intentional — defence in depth.

## Example

```bash
curl -X POST https://api.scalario.app/api/v1/blandine-shop/caisse/action \
  -H "Authorization: Bearer $JWT" \
  -H "X-Client-Mutation-Id: 11111111-2222-4333-8444-555555555551" \
  -H "Content-Type: application/json" \
  -d '{"action":"create_sale","payload":{"amount":12000}}'

# Retry the exact same request → identical response, no double sale:
# Response header `X-Idempotency-Replay: true`
```

## Metrics

Currently exposed via structured logs (prefix `idempotency.metric.*`),
to be wired to prom-client when Swagger/OpenTelemetry land (deferred
work W3). Counters tracked:

- `idempotency.metric.hit` — cached response served
- `idempotency.metric.collision` — same key with diverging body
- `idempotency.audit.user_mismatch` — replay by different user

`IdempotencyCacheService.getMetrics()` is exposed for tests.

## Known limitations

- **Mutation > 24h pending**: if a Drift mutation sits in queue >24h,
  the server-side cache key has expired. The mutation will re-execute
  (and the natural-key DB constraints on the module catch real
  duplicates). Client mitigation (alert from `SyncStatusBar` at h+23) →
  STORY-037. Phase 2 may extend TTL to 7 days.
- **4xx idempotence is weaker**: Nest's exception filter consumes
  4xx errors before this interceptor's `tap` fires, so 4xx responses
  aren't cached. Determinism is preserved because the same input
  produces the same 4xx error every time.
- **Swagger annotations** (`@ApiHeader` on `X-Client-Mutation-Id`)
  deferred until `@nestjs/swagger` is installed (W3).
