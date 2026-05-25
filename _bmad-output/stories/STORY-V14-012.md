# STORY-V14-012 : Scalario Live — WebSocket Gateway NestJS + Flutter listener + FCM/APN enregistrement

**Epic :** EPIC-V14-007 — Scalario Live (Realtime Engine)
**Priorité :** Must Have
**Story Points :** 5
**Status :** defined
**Sprint :** v14-3 (2026-06-23 → 2026-07-06)
**Dépendances :** V14-001 (nomenclature), V14-005 (restructure NestJS), STORY-014 v13 (Auth JWT)

---

## User Story

> **En tant qu'**utilisateur ERP qui doit voir ses badges/notifications/refresh à jour en temps réel,
> **je veux** que Scalario Live (WebSocket NestJS) pousse les events serveur vers mon app dès qu'ils se produisent, et qu'en cas d'app fermée, je reçoive une notification FCM (Android) ou APN (iOS),
> **so that** quand un commercial soumet une commande > 500k XOF, le manager voit le badge "Validation" apparaître **immédiatement** — sans poll, sans refresh manuel.

---

## Description

### Background

PRD v14 §13 — Scalario Live est le **7ème engine**, le seul déclenché par le **serveur** (les 6 autres sont déclenchés par l'utilisateur). Il gère les events serveur → app :
- `validation_required` → badge + notification
- `stock_critical` → AlertBanner
- `data_updated` → invalidate cache Vault → refetch
- `config_updated` → diff téléchargé + UI rechargée silencieusement
- `payment_confirmed` → trigger pipeline post_payment (Phase 2)
- `alert_triggered` → AlertBanner overlay

### Scope

**In scope :**
- NestJS WebSocket Gateway (`src/core/live/scalario-live.gateway.ts`) authentifié JWT
- 6 events live définis (cf PRD §13.1)
- Flutter `ScalarioLiveClient` connecte au login, écoute, dispatche selon event.type
- FCM (Android) + APN (iOS) enregistrement token côté Flutter + envoi backend via `PUT /users/push-token`
- `PushService` NestJS qui décide WebSocket (app ouverte) OR FCM/APN (app fermée)
- Tests : E2E WebSocket avec 2 users (un envoie event, l'autre reçoit)

**Out of scope :**
- Push réel FCM/APN avec providers cloud (Firebase, APN cert) — Phase 2 (V14-025 ou V14 sub-story)
- ConflictReviewScreen UI — V14-026 (CRDT)
- Pipeline `post_payment` — V14-019 (Scalario Forge orchestre)

---

## Acceptance Criteria

### WebSocket Gateway NestJS

- [ ] **AC-01** — `ScalarioLiveGateway` Socket.IO ou raw WebSocket (`@WebSocketGateway`) écoutant sur `/live`.
- [ ] **AC-02** — Authentification JWT à la connexion (handshake) : `?token=<jwt>` ou header `Authorization: Bearer`.
- [ ] **AC-03** — Subscribe par tenant + user : rooms `tenant_<id>` + `user_<id>`.
- [ ] **AC-04** — Helper `ScalarioLiveService.emit(channel, event, data)` qui dispatche vers les bons sockets.

### Events live (6)

- [ ] **AC-05** — `validation_required` : payload `{ commande_id, montant, client, requested_for_role }` → badge sur `menu.validations` + notification locale.
- [ ] **AC-06** — `stock_critical` : payload `{ produit, qty_restante, seuil_min }` → AlertBanner danger sur écran actuel.
- [ ] **AC-07** — `data_updated` : payload `{ source, entity_id? }` → invalidate cache Vault → refetch.
- [ ] **AC-08** — `config_updated` : payload `{ new_version, diff_url }` → fetch diff + appliquer.
- [ ] **AC-09** — `alert_triggered` : payload `{ message, severity, component }` → AlertBanner overlay.
- [ ] **AC-10** — `session_expired` : payload `{ reason }` → redirect login + message explicatif.

### Flutter `ScalarioLiveClient`

- [ ] **AC-11** — Se connecte au login, reconnecte automatiquement (exponential backoff).
- [ ] **AC-12** — Écoute `LiveEvent` stream, dispatche selon `event.type` via switch.
- [ ] **AC-13** — `BadgeManager.increment(target)` + `NotificationService.show(local)` + `ScalarioVault.invalidate(source)` câblés.

### FCM / APN enregistrement

- [ ] **AC-14** — Flutter récupère le token (Firebase Messaging Android, APN iOS) au login.
- [ ] **AC-15** — Envoie au backend : `PUT /api/v1/users/push-token { token, platform: 'android' | 'ios' | 'web' }`.
- [ ] **AC-16** — Backend stocke dans `users.push_tokens` JSONB (1 user peut avoir plusieurs devices).

### PushService backend

- [ ] **AC-17** — `PushService.notify(userId, payload)` : si user connecté WebSocket → emit ; sinon → FCM/APN (Phase 1 = stub `console.log('would send FCM')`).
- [ ] **AC-18** — En Phase 2 (V14-025 ou suiteancée), brancher Firebase Admin SDK + APN provider.

### Tests E2E

- [ ] **AC-19** — Test E2E WebSocket : 2 users connectés, 1er envoie `validation_required` via service, le 2e reçoit dans <100ms.
- [ ] **AC-20** — Test reconnexion : couper connexion, attendre 5s, reconnexion automatique.

---

## Technical Notes

### Architecture

```
NestJS (event métier déclenché) :
   Commande soumise → WorkflowEngine → besoin validation DG
   → ScalarioLiveService.emit('tenant_blandine_real', 'validation_required', {...})
   → WebSocket Gateway émet vers tous les DG connectés
   → Payload : { event: 'validation_required', data: {...} }

Scalario Live Flutter (écoute + dispatche) :
class ScalarioLive {
  final _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
  void init() {
    _channel.stream.listen((raw) {
      final event = LiveEvent.fromJson(raw);
      switch (event.type) {
        case 'validation_required':
          BadgeManager.increment('validations');
          NotificationService.show(event.data);
          break;
        case 'data_updated':
          ScalarioVault.invalidate(event.data.source);
          break;
        // ...
      }
    });
  }
}
```

### Push notifications hors app — FCM & APN

```typescript
// PushService.ts
@Injectable()
export class PushService {
  async notify(userId: string, payload: PushPayload) {
    const user = await this.userRepo.findOne(userId);

    // WebSocket si connecté (app ouverte)
    if (this.scalarioLive.isConnected(userId)) {
      return this.scalarioLive.emit(userId, payload);
    }

    // FCM/APN si app fermée (Phase 2 = stub)
    if (user.fcmToken) {
      // Phase 1 stub :
      this.logger.log(`Would send FCM to ${user.fcmToken}: ${JSON.stringify(payload)}`);
      // Phase 2 (V14-026) :
      // await this.fcm.send({ token, notification: { title, body }, data: {...} });
    }
  }
}
```

### Edge cases

- Reconnexion : exponential backoff 1s, 2s, 4s, 8s, max 30s
- Backpressure : si stream backed up, drop events `data_updated` (re-fetch va catch-up)
- Token expiré : reconnect avec nouveau JWT (Flutter re-authentifie)
- Multi-device : 1 user → N sockets actifs

---

## Dependencies

- **Prérequis :** V14-001, V14-005, STORY-014 v13 (auth JWT)
- **Stories bloquées :** V14-022 (anti-hallucination — config_updated event), V14-026 (CRDT — conflict events)

---

## Definition of Done

- [ ] WebSocket Gateway NestJS opérationnel
- [ ] Flutter ScalarioLiveClient (reconnect + dispatch)
- [ ] FCM/APN token enregistrement (Phase 1 stub backend)
- [ ] 6 events documentés et testés
- [ ] 2 tests E2E (WebSocket + reconnect)
- [ ] sprint-status.yaml V14-012 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| WebSocket Gateway NestJS + auth JWT + rooms | 1.5 |
| Flutter ScalarioLiveClient (connect + reconnect + dispatch) | 1.5 |
| 6 events handlers (NestJS emit + Flutter listen) | 1.0 |
| FCM/APN token enregistrement + PushService stub | 0.5 |
| Tests E2E | 0.5 |
| **Total** | **5** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
