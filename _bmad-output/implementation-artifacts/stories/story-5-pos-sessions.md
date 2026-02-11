# Story 5: POS Session Management (Open/Close till)

**Goal:** Ensure all financial transactions are boxed within a trackable session with opening and closing balances.

## Context
A cashier must open a "session" (caisse) before being able to process sales. This session tracks the cash float and provides a point of reconciliation at the end of the day.

## Requirements

### 1. Backend Persistence
- [x] **Prisma Model**: `PosSession` with `openingBalance`, `closingBalance`, `status` (OPEN/CLOSED), `userId`, `tenantId`.
- [x] **RLS**: Strict tenant isolation on `pos_sessions` table.
- [x] **Services**: Methods to open (preventing duplicates), close (calculating variance), and fetch active session.

### 2. Frontend Local State
- [x] **Isar Model**: `PosSession` collection.
- [x] **Repository**: Local CRUD for sessions.
- [x] **Notifier**: Riverpod `SessionNotifier` to track if the current user has an open till.

### 3. UI Flow (Flux Caisse)
- [x] **Session Guard**: A high-level wrapper that prevents access to the POS grid if no session is open.
- [x] **Open Session Screen**: A dedicated UI to enter the initial cash float.
- [x] **Close Session Dialog**: A way to enter final cash and terminate the session.

## Acceptance Criteria
- [ ] User is blocked from selling until a session is opened.
- [ ] Session data is persisted locally (Isar) and synced to backend (Supabase).
- [ ] Orders are linked to `session_id`.
- [ ] Closing a session marks it as `CLOSED` and prevents further sales until a new one is opened.
