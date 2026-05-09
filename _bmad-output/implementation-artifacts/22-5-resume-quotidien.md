# Story 22.5 — Backend : Résumé quotidien (FR86) + config canal par tenant

## Metadata

- **Epic:** Epic 22 — Alertes stock bas + notifications
- **Story ID:** 22-5-resume-quotidien
- **Status:** done
- **Priority:** Medium
- **Depends on:** 22-4 (NotificationsService disponible), Epic 21 (PurchaseOrdersService)

---

## Story

**As a** owner,
**I want** to receive a daily summary notification at a configured time, and to control this setting from the admin panel,
**So that** I stay informed of daily performance without opening the app every day (FR86).

---

## Acceptance Criteria

### AC1 — Config tenant pour résumé quotidien

**Given** `PATCH /api/v1/tenants/notification-settings` est appelé avec `{ dailySummaryEnabled: true, dailySummaryTime: "18:00", notificationChannel: "in_app" }`
**When** la requête est validée
**Then** les champs `dailySummaryEnabled`, `dailySummaryTime`, `notificationChannel` sont mis à jour sur le `Tenant`
**And** seul un utilisateur avec le rôle `owner` peut appeler cet endpoint
**And** la réponse renvoie les settings mis à jour

### AC2 — Cron job résumé quotidien

**Given** le cron job `DailySummaryJob` est planifié et `dailySummaryEnabled = true` pour un tenant
**When** l'heure locale du tenant (timezone) atteint `dailySummaryTime`
**Then** le système calcule pour la journée : total ventes (`transactionCount`), chiffre d'affaires (`totalRevenue`), nouvelles alertes stock bas (`newAlerts`), commandes en attente (`pendingPOs`)
**And** une notification in-app est persistée pour tous les `owner` du tenant
**And** le corps de la notification inclut ces 4 métriques formatées

### AC3 — Canal WhatsApp (stub Phase 2b)

**Given** `notificationChannel = "whatsapp"` est configuré
**When** le résumé quotidien est envoyé
**Then** le système log "WhatsApp channel not yet implemented — fallback to in_app" et envoie la notification in-app
**And** aucune erreur n'est levée (graceful degradation)

### AC4 — Frontend — Section "Notifications" dans le panel admin tenant

**Given** l'administrateur ouvre le panel de configuration tenant (`TenantSettingsScreen`)
**When** la section "Notifications" s'affiche
**Then** un toggle "Résumé quotidien activé" est visible
**And** si le toggle est ON, un champ "Heure d'envoi" (time picker, format HH:mm) est visible
**And** un sélecteur "Canal" propose "Application (in-app)" et "WhatsApp (bientôt disponible)" (WhatsApp grisé)
**And** les modifications sont sauvegardées via `PATCH /api/v1/tenants/notification-settings`

### AC5 — Timezone awareness

**Given** le cron job évalue quels tenants envoyer
**When** le job s'exécute toutes les minutes
**Then** seuls les tenants dont `dailySummaryTime` correspond à l'heure courante dans leur `timezone` sont traités
**And** chaque tenant n'est traité qu'une fois par jour (idempotence via un flag `lastSummarySentDate`)

---

## Tasks/Subtasks

- [ ] **Task 1 : Migration — champs notification sur Tenant**
  - [ ] Ajouter sur `Tenant` : `dailySummaryEnabled Boolean @default(false)`, `dailySummaryTime String? @default("18:00")`, `notificationChannel String @default("in_app")`, `lastSummarySentDate DateTime?`
  - [ ] Générer migration

- [ ] **Task 2 : Endpoint notification-settings**
  - [ ] Ajouter `PATCH /tenants/notification-settings` dans `tenants.controller.ts`
  - [ ] Méthode `updateNotificationSettings()` dans `tenants.service.ts`
  - [ ] Guard : `@Roles('owner')`

- [ ] **Task 3 : DailySummaryJob**
  - [ ] Créer `daily-summary.job.ts` avec `@nestjs/schedule` `@Cron('* * * * *')`
  - [ ] Query tenants avec `dailySummaryEnabled = true`
  - [ ] Évaluer timezone : heure courante du tenant == `dailySummaryTime`
  - [ ] Idempotence : vérifier `lastSummarySentDate != today`
  - [ ] Calculer métriques via services existants
  - [ ] Persister notification + mettre à jour `lastSummarySentDate`
  - [ ] WhatsApp : logger fallback, pas d'erreur

- [ ] **Task 4 : Frontend — TenantSettingsScreen section Notifications**
  - [ ] Toggle "Résumé quotidien activé"
  - [ ] TimePicker "Heure d'envoi" (visible si toggle ON)
  - [ ] Dropdown canal : "Application (in-app)" activé, "WhatsApp" grisé
  - [ ] Sauvegarder via `PATCH /api/v1/tenants/notification-settings`

---

## Files to Create

- `apps/backend/src/shared/notifications/jobs/daily-summary.job.ts`

## Files to Modify

- `apps/backend/src/kernel/tenants/tenants.controller.ts` — `PATCH notification-settings`
- `apps/backend/src/kernel/tenants/tenants.service.ts` — `updateNotificationSettings()`
- `apps/backend/prisma/schema.prisma` — champs notification sur `Tenant`
- `apps/frontend/lib/features/admin/presentation/screens/tenant_settings_screen.dart` — section Notifications
- `apps/backend/src/shared/purchase-orders/purchase-orders.controller.ts` — `GET /stats`

## Dev Notes

- Utiliser `@nestjs/schedule` (`@Cron('* * * * *')`) pour le job minute-by-minute
- `lastSummarySentDate` peut être un champ `DateTime?` sur `Tenant` (MVP : champ Tenant)
- Le calcul des métriques réutilise les services existants : `TransactionsService`, `StockAlertsService`, `PurchaseOrdersService`
