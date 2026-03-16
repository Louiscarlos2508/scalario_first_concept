# Story 18.2 — Frontend : Service d'identité device + envoi `deviceId`

## Metadata
- **Epic:** Epic 18 — Lien Session Caisse ↔ Terminal Physique
- **Story ID:** 18-2-device-identity-service-frontend
- **Status:** done
- **Priority:** High
- **Depends on:** 18-1 backend done

---

## Story

**As a** cashier working on a physical POS terminal,
**I want** my device to have a stable, readable identity,
**So that** the backoffice always knows which physical terminal I'm working on.

---

## Acceptance Criteria

1. **`DeviceIdentityService`** (`lib/core/services/device_identity_service.dart`) :
   - `getDeviceId()` → `Future<String>`
   - Premier appel : génère `caisse-{platform}-{6-char-hex}`, persiste dans `SharedPreferences` sous `scalario_device_id`
   - Appels suivants : retourne la valeur persistée (jamais regénérée)
   - Platform tag : `android`, `windows`, `linux`, `web`, `ios`

2. **Ouverture de session POS** :
   - `SessionNotifier.openSession()` appelle `DeviceIdentityService.getDeviceId()`
   - Le `deviceId` est inclus dans le body de `POST /retail/sessions/open`
   - Le `deviceId` est stocké sur le modèle Isar `PosSession.deviceId`

3. **Sync adapter** :
   - `SessionSyncAdapter.pushPending()` inclut `deviceId` dans le payload JSON envoyé au backend

4. **Heartbeat** :
   - `SyncService._sendHeartbeat()` utilise `DeviceIdentityService.getDeviceId()` au lieu de `"terminal_linux_1"` hardcodé

---

## Tasks/Subtasks

- [x] **Task 1 : `DeviceIdentityService`**
  - [x] Créer `lib/core/services/device_identity_service.dart`
  - [x] Dépendance `shared_preferences` (déjà dans pubspec)
  - [x] Génération : `dart:math` Random + hex encoding

- [x] **Task 2 : Modèle Isar `PosSession`**
  - [x] Ajouter champ `deviceId String?` sur le modèle Isar
  - [x] Regénérer `pos_session.g.dart` (`dart run build_runner build`)

- [x] **Task 3 : `SessionNotifier.openSession()`**
  - [x] Injecter `DeviceIdentityService`
  - [x] Passer `deviceId` au body HTTP et au modèle Isar local

- [x] **Task 4 : `SessionSyncAdapter`**
  - [x] Inclure `session.deviceId` dans le JSON du push

- [x] **Task 5 : `SyncService._sendHeartbeat()`**
  - [x] Utiliser `DeviceIdentityService.getDeviceId()` (appel async dans l'isolate)
