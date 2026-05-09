# Story 18.1 — Backend : `deviceId` sur `PosSession`

## Metadata
- **Epic:** Epic 18 — Lien Session Caisse ↔ Terminal Physique
- **Story ID:** 18-1-device-id-pos-session-backend
- **Status:** done
- **Priority:** High
- **Depends on:** Epic 16 done (PosSession opérationnel)

---

## Story

**As a** platform developer,
**I want** `PosSession` to store the `deviceId` of the physical terminal that opened it,
**So that** backoffice reports can show which device is running which session.

---

## Acceptance Criteria

1. **Prisma schema** — `PosSession` :
   - Nouveau champ `deviceId String? @map("device_id")` (nullable, pas UUID — string lisible ex. `"caisse-android-a3f9c2"`)
   - Migration générée et appliquée

2. **`POST /retail/sessions/open`** :
   - Accepte `deviceId?: string` dans le body
   - Passe `deviceId` à `PosSessionService.openSession()`
   - `openSession()` stocke `deviceId` sur la session créée

3. **`POST /pos/sessions`** (sync) :
   - `syncSession()` préserve `deviceId` sur upsert (create + update)

4. **`GET /retail/sessions/active?tenantId=`** :
   - Chaque session dans la réponse inclut `deviceId`

---

## Tasks/Subtasks

- [x] **Task 1 : Prisma schema**
  - [x] Ajouter `deviceId String? @map("device_id")` sur `PosSession`
  - [x] `prisma migrate dev --name add_device_id_to_pos_sessions`

- [x] **Task 2 : `PosSessionService.openSession()`**
  - [x] Ajouter `deviceId?: string` au paramètre data
  - [x] Inclure `deviceId` dans `prisma.posSession.create()`

- [x] **Task 3 : `RetailSessionController.openSession()`**
  - [x] Ajouter `deviceId?: string` au body destructuring
  - [x] Passer au service

- [x] **Task 4 : `PosSessionService.syncSession()`**
  - [x] Préserver `deviceId` sur create et update

- [x] **Task 5 : Vérification `GET /retail/sessions/active`**
  - [x] Le champ `deviceId` est retourné dans la réponse (Prisma retourne tous les champs par défaut)
