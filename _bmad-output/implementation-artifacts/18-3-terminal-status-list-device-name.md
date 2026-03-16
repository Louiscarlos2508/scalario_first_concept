# Story 18.3 — Frontend : "État des caisses" affiche le nom du terminal

## Metadata
- **Epic:** Epic 18 — Lien Session Caisse ↔ Terminal Physique
- **Story ID:** 18-3-terminal-status-list-device-name
- **Status:** done
- **Priority:** High
- **Depends on:** 18-1, 18-2 done

---

## Story

**As a** store owner viewing the backoffice dashboard,
**I want** "État des caisses" to show the name of each active terminal,
**So that** I can instantly identify which physical device is working.

---

## Acceptance Criteria

1. **`TerminalStatusList`** — chaque card de session :
   - Title : `deviceId` si non-null, `"Terminal inconnu"` si null
   - Subtitle : `Depuis HH:mm • Fond: XX FCFA`
   - Trailing chip : `EN COURS` (vert)

2. **Auto-refresh** :
   - Le timer 30s dans `OverviewScreen` invalide `activeSessionsProvider`
   - Une nouvelle session ouverte sur un autre terminal apparaît dans les 30s

3. **Tests** (`test/dashboard_sdui_integration_test.dart`) :
   - Mock avec `deviceId: "caisse-test-001"` → `find.text("caisse-test-001")` trouvé
   - Mock avec `deviceId: null` → `find.text("Terminal inconnu")` trouvé

---

## Tasks/Subtasks

- [x] **Task 1 : `TerminalStatusList`**
  - [x] Afficher `s['deviceId'] as String? ?? 'Terminal inconnu'` comme title
  - [x] Garder subtitle existant (heure + fond)

- [x] **Task 2 : Tests**
  - [x] Ajouter 2 cas de test dans `dashboard_sdui_integration_test.dart`
  - [x] Mock `activeSessionsProvider` avec session `deviceId` non-null
  - [x] Mock `activeSessionsProvider` avec session `deviceId: null`
