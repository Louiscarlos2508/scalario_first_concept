# STORY-V14-025 : Scalario Sense — Mobile Money (Wave + Orange Money + MTN MoMo + webhooks NestJS HMAC)

**Epic :** EPIC-V14-016 — Scalario Sense
**Priorité :** Must Have
**Story Points :** 8
**Status :** defined
**Sprint :** v14-8 (Phase 2)
**Dépendances :** V14-024 (CapabilityRegistry), STORY-042 v13 (PaymentAdapter stubs backend — à supprimer)

---

## User Story

> **En tant qu'**utilisateur ERP qui veut être payé en Wave, Orange Money, ou MTN MoMo,
> **je veux** que le paiement Mobile Money fonctionne nativement depuis l'app (capability `wave_pay`, `orange_money`, `mtn_momo`), avec confirmation asynchrone via webhook NestJS HMAC-signé,
> **so that** Aïcha peut encaisser un paiement Wave en 1 tap, le commerçant reçoit l'argent en quelques secondes, et le système est notifié automatiquement.

---

## Description

### Background

PRD v14 §11.2 — Mobile Money est une capability Scalario Sense (côté Flutter, pas backend) pour la partie initiate. La confirmation passe par un webhook NestJS qui :
1. Vérifie la signature HMAC du provider
2. Met à jour `paiements.status`
3. Déclenche Scalario Live `payment_confirmed`
4. Déclenche le pipeline post-paiement (facturation auto)

C'est la migration de STORY-042 v13 (PaymentAdapter NestJS stubs) vers une vraie implémentation Phase 2.

### Scope

**In scope :**
- Migration STORY-042 v13 : supprimer `src/payment/` NestJS (PaymentAdapter stubs)
- Capabilities Flutter Phase 2 dans `catalog/capabilities/payment/` :
  - `wave_pay.json` (Wave Senegal SDK ou API)
  - `orange_money.json` (OM CI, OM SN — variantes pays)
  - `mtn_momo.json` (MTN MoMo Open API)
- Flutter capability layer : `lib/core/sense/payment/` (ScannerCapability pattern)
- Webhook NestJS : `POST /api/v1/webhooks/mobile-money` (HMAC SHA-256 verify)
- WebhookSignatureGuard NestJS
- Test E2E : initiate Wave en sandbox → callback webhook → update paiement → Scalario Live event
- Documentation runbook : configurer credentials Wave/OM/MTN par tenant

**Out of scope :**
- Cross-tenant Mobile Money (Phase 4 Scalario Network)
- Reconciliation bancaire automatique — Phase 3
- Wave/OM/MTN officials production credentials acquisition — Carlos responsable business side

---

## Acceptance Criteria

### Capabilities Flutter

- [ ] **AC-01** — `wave_pay`, `orange_money` (`_ci`, `_sn`, `_bf` variants), `mtn_momo` capabilities créées.
- [ ] **AC-02** — `CapabilityRegistry.invoke('wave_pay', { montant, phone, ref })` → ouvre SDK Wave → retourne `{ tx_id, status: 'pending', provider: 'wave' }`.
- [ ] **AC-03** — Mode sandbox vs prod : env `WAVE_ENV=sandbox|prod`.
- [ ] **AC-04** — Test mocks en dev : `kDebugMode` retourne `{ tx_id: 'sandbox_xxx', status: 'success' }` immédiat.

### Webhook NestJS

- [ ] **AC-05** — `POST /api/v1/webhooks/mobile-money` endpoint public.
- [ ] **AC-06** — `WebhookSignatureGuard` vérifie HMAC SHA-256 header `X-Webhook-Signature` avec secret tenant.
- [ ] **AC-07** — Si signature invalide → 401 + audit log `event: 'webhook_invalid_signature'`.
- [ ] **AC-08** — Si signature OK → update `paiements.status` + déclenche `ScalarioLive.emit('payment_confirmed')`.
- [ ] **AC-09** — Si pipeline `post_payment` déclaré pour ce tenant → ScalarioFlow.trigger.

### Tests

- [ ] **AC-10** — Test E2E sandbox Wave : initiate → callback webhook simulé → state update.
- [ ] **AC-11** — Test signature HMAC : signature invalide → 401, signature valide → 200.
- [ ] **AC-12** — Test idempotence webhook : 2 callbacks identiques → 1 seul update (via STORY-036 idempotency).

### Config tenant

- [ ] **AC-13** — `tenant.config.payment_providers = { wave: { api_key, secret, env }, orange_money_ci: {...}, mtn_momo: {...} }`.
- [ ] **AC-14** — Endpoint admin pour configurer per-tenant : `PATCH /api/v1/tenants/:slug/payment_config` (OWNER+SUPER_ADMIN).

### Migration STORY-042 v13

- [ ] **AC-15** — Suppression `src/payment/` v13 (PaymentAdapter stubs backend).
- [ ] **AC-16** — Migration `tenant.config.payment_methods_enabled` (STORY-039 v13) → `tenant.config.payment_providers` v14 (avec credentials).

---

## Technical Notes

### Flutter capability example

```dart
class WavePayCapability extends Capability<WavePayInput, WavePayResult> {
  String get id => 'wave_pay';
  bool get isAvailable => Platform.isAndroid || Platform.isIOS;

  Future<WavePayResult> execute(WavePayInput input) async {
    if (kDebugMode || _env == 'sandbox') {
      return WavePayResult(tx_id: 'sandbox_${Uuid().v4()}', status: 'pending');
    }
    // Wave SDK call
    final result = await WaveSDK.initPayment(
      amount: input.montant,
      phone: input.phone,
      reference: input.ref,
    );
    return WavePayResult(tx_id: result.txId, status: 'pending', provider: 'wave');
  }
}
```

### Webhook NestJS

```typescript
@Post('webhooks/mobile-money')
@UseGuards(WebhookSignatureGuard)
async handleWebhook(@Body() payload: MobileMoneyWebhook) {
  const { tx_id, status, provider } = payload;

  // Idempotency check (STORY-036)
  await this.paymentService.updateStatus(tx_id, status);

  // Trigger Scalario Live
  await this.scalarioLive.emit('payment_confirmed', { tx_id, status, provider });

  // Trigger post-payment pipeline
  if (status === 'success') {
    await this.scalarioFlow.trigger('post_payment', { tx_id });
  }

  return { ok: true };
}
```

### Edge cases

- Webhook delivered 2x (provider retry) → idempotency catches
- Webhook delayed (5 min) → state pending continue affiché tant que callback pas reçu
- Provider down → user retry manuel, log alerte si > 10% échec
- Signature mismatch (clé tenant changée) → log audit + 401

---

## Dependencies

- **Prérequis :** V14-024 (CapabilityRegistry), STORY-036 v13 (idempotency)
- **Stories bloquées :** V14-022 (anti-hallucination — payment est sensible, fallback Claude possible)

---

## Definition of Done

- [ ] 3 providers Mobile Money capabilities Flutter
- [ ] Webhook NestJS + HMAC guard
- [ ] STORY-042 v13 supprimée (migration)
- [ ] Tests E2E sandbox + signature + idempotence
- [ ] Runbook config tenant
- [ ] sprint-status.yaml V14-025 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| 3 capabilities Flutter (Wave, OM, MTN MoMo) | 3.0 |
| Webhook NestJS + HMAC guard | 1.5 |
| Tests E2E | 1.5 |
| Migration STORY-042 v13 | 1.0 |
| Config tenant + runbook | 1.0 |
| **Total** | **8** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
