# Story 22.4 — Backend : Service notification (event, push in-app v1)

## Metadata

- **Epic:** Epic 22 — Alertes stock bas + notifications
- **Story ID:** 22-4-service-notification
- **Status:** done
- **Priority:** Medium
- **Depends on:** 22-1 (LowStockDetected event émis)

---

## Story

**As a** backend developer,
**I want** a notification service that listens for low-stock events and sends in-app push notifications to authorized users,
**So that** managers and owners are alerted in real-time when stock drops below threshold (FR82).

---

## Acceptance Criteria

### AC1 — Listener LowStockDetected

**Given** l'Event Bus reçoit un événement `LowStockDetected { tenantId, catalogItemId, itemName, stockQuantity, minStockLevel }`
**When** le `NotificationService` traite l'événement
**Then** une notification in-app est persistée pour tous les utilisateurs du tenant ayant le rôle `owner` ou `manager`
**And** la notification contient : titre "Stock critique", corps "X — il reste Y unité(s) (seuil : Z)", et `catalogItemId` comme deep-link cible
**And** la notification est marquée `unread` à la création

### AC2 — Endpoint GET notifications non lues

**Given** `GET /api/v1/notifications?unread=true` est appelé
**When** le backend répond
**Then** la réponse renvoie la liste des notifications non lues de l'utilisateur courant
**And** chaque notification inclut : `id`, `title`, `body`, `type`, `targetId`, `createdAt`, `isRead`
**And** l'endpoint est paginé (`?limit=`, `?offset=`)

### AC3 — Endpoint POST marquer comme lue

**Given** `POST /api/v1/notifications/:id/read` est appelé
**When** le backend répond
**Then** la notification est marquée `isRead: true`
**And** la réponse renvoie `{ success: true }`

### AC4 — Endpoint GET count non lues

**Given** `GET /api/v1/notifications/unread-count` est appelé
**When** le backend répond
**Then** la réponse renvoie `{ unreadCount: number }`
**And** ce count est utilisé par le frontend pour afficher le badge de notification dans l'AppBar

### AC5 — Isolation tenant

**Given** deux tenants ont des alertes stock bas
**When** l'endpoint notifications est appelé pour un utilisateur du tenant A
**Then** seules les notifications du tenant A sont retournées — aucune fuite cross-tenant

---

## Tasks/Subtasks

- [ ] **Task 1 : Migration — table notifications**
  - [ ] Ajouter table `notifications` dans schema `shared` : `id, tenantId, userId, type, title, body, targetId, isRead, createdAt`
  - [ ] Générer migration

- [ ] **Task 2 : NotificationsModule**
  - [ ] Créer `notifications.module.ts`, `notifications.service.ts`, `notifications.controller.ts`
  - [ ] Méthodes : `createNotification()`, `getUserNotifications()`, `markAsRead()`, `getUnreadCount()`

- [ ] **Task 3 : Listener LowStockDetected**
  - [ ] Dans `notifications.service.ts`, `@OnEvent('LowStockDetected')`
  - [ ] Query users du tenant avec rôle owner/manager
  - [ ] Persister une notification par utilisateur éligible

- [ ] **Task 4 : DTO**
  - [ ] `NotificationDto` : `id, title, body, type, targetId, createdAt, isRead`

- [ ] **Task 5 : Enregistrement**
  - [ ] Importer `NotificationsModule` dans `AppModule`
  - [ ] S'assurer que l'EventBus est partagé entre `StockAlertsModule` et `NotificationsModule`

---

## Files to Create

- `apps/backend/src/shared/notifications/notifications.module.ts`
- `apps/backend/src/shared/notifications/notifications.service.ts`
- `apps/backend/src/shared/notifications/notifications.controller.ts`
- `apps/backend/src/shared/notifications/dto/notification.dto.ts`
- `apps/backend/prisma/migrations/YYYYMMDD_add_notifications_table/migration.sql`

## Files to Modify

- `apps/backend/src/shared/stock-alerts/stock-alerts.service.ts` — émettre `LowStockDetected`
- `apps/backend/src/app.module.ts` — enregistrer `NotificationsModule`

## Dev Notes

- Phase 2b : intégration WhatsApp Business API (hors scope de cette story)
- Phase 2b : FCM/APNs push mobile (hors scope — in-app only pour v1)
