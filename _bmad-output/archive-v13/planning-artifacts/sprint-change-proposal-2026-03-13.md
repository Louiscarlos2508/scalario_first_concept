# Sprint Change Proposal — PRD v5 Course Correction

**Date:** 2026-03-13
**Author:** Carlos-simpore
**Workflow:** Correct Course (BMAD BMM)
**Status:** Approved
**Scope Classification:** Major — requires PRD update (done), epics update, and architecture update

---

## Section 1: Issue Summary

### Problem Statement

The architecture document (`docs/architecture-scalario-2026-03-08.md` v1.0) and the epic breakdown (`_bmad-output/planning-artifacts/epics.md`) were designed against **PRD v1** (54 FRs). The PRD has since been updated to **v5.0** (75 FRs, 2026-03-11), adding 3 new product dimensions and 21 new functional requirements that are not reflected in either the architecture or the epics.

### Discovery Context

- **When:** Identified before Story 1.2 starts. Story 1.1 (Kernel Schema, Tenant Management & Authentication) is the only implemented story.
- **Trigger:** Deliberate PRD upgrade (v1 → v5), not a story failure.
- **Timing:** Optimal — minimal rework required. Only 1 of 9 planned epics has been partially executed.

### Evidence

| Dimension | PRD v1 | PRD v5 | Gap |
|:---|:---|:---|:---|
| Total FRs | 54 | 75 | +21 (+39%) |
| UI approach | Standard Flutter screens | Server-Driven UI (JSON layouts, single binary) | Architecture gap |
| Scalario Connect (B2B) | ❌ | FR52–FR55 Phase 1 DB + Phase 3 business logic | Architecture + DB gap |
| Scalario Enterprise | ❌ | FR59–FR75 Phase 1 DB + Phase 3 business logic | Architecture + RBAC gap |
| Programme Ambassadeurs | ❌ | `referred_by` on Tenant (Phase 2b) | DB schema gap |
| RBAC roles | 3 (Owner/Manager/Commercial) | 5 (+ DepartmentAdmin, Employee for Enterprise) | Story 1.2 gap |
| User Journeys | 5 (Retail) | 8 (+Awa/DRH, Ibrahim/Comptable, Serge/DG) | Epic coverage gap |
| FR numbers FR52–FR54 | Migration, Prisma, Sync | Renumbered to FR56–FR58 | Traceability gap |

---

## Section 2: Impact Analysis

### Epic Impact

| Epic | Status | Impact |
|:---|:---|:---|
| Epic 1: Kernel | 🟡 Modify | Story 1.2: add 2 Enterprise roles to RBAC seed. Story 1.3: add connect + enterprise modules to registry. New Story 1.6: Phase 3 DB anticipation migration. |
| Epic 2: Shared Catalog | 🟢 Valid | No scope change. FR13 gets a SDUI dynamic layer via Epic 10, but Epic 2's catalog data model is unchanged. |
| Epic 3: Shared Contacts | 🟢 Valid | No scope change. linked_tenant_id (FR53) added as a nullable field via Story 1.6 — no contact business logic changes. |
| Epic 4: Shared Transactions | 🟢 Valid | No scope change. transfer_inter_tenant enum value (FR55) added via Story 1.6 — no transaction business logic changes. |
| Epic 5: Shared Inventory | 🟢 Valid | No scope change. Enterprise import is Phase 3. |
| Epic 6: Retail Vertical | 🟢 Valid | No scope change. Ambassadeurs referred_by is tracked at Tenant level, not POS. |
| Epic 7: Reporting & BI | 🟢 Valid | No scope change. Enterprise/OHADA reports are Phase 3. |
| Epic 8: Frontend Sync | 🟡 Modify | FR58 (renumbered from FR54) + FR75 (Sync Failure Lifecycle) added to scope. |
| Epic 9: Data Migration | 🟡 Modify | FR56–FR57 (renumbered from FR52–FR53) — no content change, number correction only. |
| Epic 10: Server-Driven UI | ✨ NEW | After Epic 6, before Epic 7. Covers FR13 dynamic layer. |
| Epic 11: Programme Ambassadeurs | ✨ NEW | Phase 2b. FR52 business logic (DB seeded in Story 1.6). |
| Epic 12: Scalario Connect | ✨ NEW | Phase 3. FR52–FR55 business logic (DB seeded in Story 1.6). |
| Epic 13: Scalario Enterprise | ✨ NEW | Phase 3. FR59–FR75 business logic (DB seeded in Story 1.6). |

### Artifact Conflicts

| Artifact | Status | Required Changes |
|:---|:---|:---|
| `_bmad-output/planning-artifacts/prd.md` | ✅ Already v5.0 | No changes — source of truth |
| `_bmad-output/planning-artifacts/epics.md` | 🔴 Out of date | Story 1.2 edit, Story 1.3 edit, new Story 1.6, Epics 10–13, FR Coverage Map (FR52–FR75) |
| `docs/architecture-scalario-2026-03-08.md` | 🔴 Out of date | 6 sections: Architectural Drivers, High-Level Architecture, Data Architecture, FR Traceability, NFR Traceability, Trade-offs |
| CI/CD pipeline | ✅ Valid | No changes |
| Testing strategy | 🟡 Note | PRD v5 QA section adds new test scenarios (Enterprise RBAC, SDUI layout validation, sync failure lifecycle) — document when starting Epic 8/10 |

### Technical Impact

- **DB:** All new fields (referred_by, network_visible, org_mode, parent_tenant_id, department_ids, department_id, linked_tenant_id, supplier_reference) are nullable or have safe defaults — zero breaking change for 3 existing clients.
- **Guards:** ModuleGuard must be designed mode-aware from Story 1.3 (check org_mode before enforcing single-vertical constraint per FR10 v5).
- **Event Bus:** FR62 (inter-department events) extends Story 1.4's event bus — no redesign, only new event type definitions in Phase 3.
- **Flutter:** Epic 10 (SDUI) deferred to after Epic 6 — existing screens built conventionally, refactored to layout engine in Epic 10.

---

## Section 3: Recommended Approach

**Selected:** Option 1 — Direct Adjustment (additive changes only, no rollback, no MVP reduction)

### Rationale

| Factor | Assessment |
|:---|:---|
| Timeline impact | Near-zero. Phase 1 (Epics 1–9) proceeds as planned. Story 1.6 adds ~0.5 day. Epic 10 deferred to post-Epic 6. |
| Technical risk | Very low. All DB changes are nullable/defaults. Story 1.1 deployed as-is — no rework. |
| Team momentum | Preserved. Story 1.2 can start immediately after this proposal is applied. No confusion. |
| Long-term sustainability | High. Phase 3 DB anticipation now prevents a zero-downtime migration on a live multi-tenant system. |
| MVP impact | None. Phase 1 MVP (Retail POS for UEMOA SMBs) is unchanged. |

### Revised Epic Sequence

```
Phase 1:
  Epic 1  → Kernel (✅ Story 1.1 done; Stories 1.2, 1.3 modified; new Story 1.6)
  Epic 2  → Shared Catalog
  Epic 3  → Shared Contacts
  Epic 4  → Shared Transactions & Payments
  Epic 5  → Shared Inventory
  Epic 6  → Retail Vertical
  Epic 10 → Server-Driven UI Infrastructure  ← NEW, inserted after Epic 6
  Epic 7  → Reporting & BI
  Epic 8  → Frontend Sync & Offline (+ FR75 Sync Failure Lifecycle)
  Epic 9  → Data Migration & Client Cutover

Phase 2b:
  Epic 11 → Programme Ambassadeurs

Phase 3:
  Epic 12 → Scalario Connect
  Epic 13 → Scalario Enterprise
```

---

## Section 4: Detailed Change Proposals

### A1 — `epics.md` Story 1.2: RBAC seed + single-vertical guard

**Story:** 1.2 — Role-Based Access Control (RBAC)

**Change 1 — Seed step:**

OLD:
```
Given the system initializes
When the seed script runs
Then MVP roles are created for retail vertical: Owner (full access),
Manager (stock/reports), Commercial (POS/sales), each with predefined
permissions matching the PRD RBAC matrix
```

NEW:
```
Given the system initializes
When the seed script runs
Then MVP Retail roles are seeded: Owner (full access), Manager (stock/reports),
Commercial (POS/sales), each with predefined permissions matching the PRD v5
RBAC Retail matrix
And two Phase-3-reserved roles are seeded with zero active permissions:
  - DepartmentAdmin (Enterprise: department-level management)
  - Employee (Enterprise: basic access within department)
  Each marked with a `phase` metadata field ('phase3') so they are
  non-activatable in Phase 1 but require no schema migration to enable in Phase 3
```

**Change 2 — One-vertical-per-tenant guard:**

OLD:
```
Given a tenant already has one active vertical
When admin attempts to activate a second vertical
Then the system rejects the activation (MVP: one vertical per tenant)
```

NEW:
```
Given a tenant with org_mode='standalone' already has one active vertical
When admin attempts to activate a second vertical
Then the system rejects the activation (Retail mode: one vertical per tenant)
Note: In Phase 3 Enterprise mode (org_mode='integrated'), multiple
department-specific verticals are allowed — ModuleGuard must check
org_mode before enforcing the single-vertical constraint
```

**Rationale:** PRD v5 FR3 extends RBAC to 5 roles. Seeding them now prevents a future breaking migration. FR10 v5 scopes the single-vertical constraint to Retail mode only.

---

### A2 — `epics.md` Story 1.3: Module Registry seed + activation guard

**Story:** 1.3 — Module Registry & Activation

**Change 1 — Seed step:**

OLD:
```
Given the system initializes
When the seed script runs
Then shared modules (catalog, transactions, inventory, payments, contacts,
reporting) and the retail vertical are registered with correct dependency
declarations
```

NEW:
```
Given the system initializes
When the seed script runs
Then shared modules (catalog, transactions, inventory, payments, contacts,
reporting) and the retail vertical are registered with correct dependency
declarations
And two Phase-3 modules are pre-registered with status='available_phase3'
and activatable=false:
  - connect: type='vertical', depends_on=[]
  - enterprise: type='vertical',
    depends_on=[catalog, contacts, transactions, reporting]
So that Phase 3 launch requires only a status flag update, never a new
seed migration on a live multi-tenant system
```

**Change 2 — Activation guard (align with FR10 v5):**

OLD:
```
Given a tenant already has one active vertical
When admin attempts to activate a second vertical
Then the system rejects the activation (MVP: one vertical per tenant)
```

NEW:
```
Given a tenant with org_mode='standalone' already has one active vertical
When admin attempts to activate a second vertical
Then the system rejects the activation
Given a tenant with org_mode='integrated' (Enterprise Phase 3)
When admin activates a vertical scoped to a specific department
Then the system allows it — multi-vertical is valid in Enterprise mode
Note: ModuleGuard checks org_mode before enforcing the constraint;
the guard logic must be written to be mode-aware from day one
```

**Rationale:** PRD v5 FR7/FR8 require the module registry to be aware of all future modules. Pre-registering them means Phase 3 launch = flip a flag, not a migration.

---

### A3 — `epics.md` New Story 1.6: Phase 3 DB Anticipation Fields

**Insert:** After Story 1.5 in Epic 1

```markdown
### Story 1.6: Phase 3 DB Anticipation Fields

As a system architect,
I want to add all Phase 2b/3 anticipation fields in a single dedicated
Prisma migration,
So that Scalario Connect, Enterprise, and Programme Ambassadeurs can
be activated in future phases without a breaking migration on a live
multi-tenant system.

**Note:** This story contains zero business logic. It is a schema-only
migration. All new fields are nullable or have safe defaults. No
endpoint, service, or guard is modified.

**Acceptance Criteria:**

**Given** all Epic 1 stories (1.1–1.5) are complete
**When** the Phase 3 anticipation migration runs
**Then** the following fields are added with zero data loss and zero
downtime for existing tenants:

kernel.tenants:
  - referred_by       UUID nullable FK → tenants.id   (FR52, Ambassadeurs Ph2b)
  - network_visible   Boolean default false            (FR52, Connect Ph3)
  - org_mode          Enum(standalone|integrated|federated) default standalone
                                                       (FR59, Enterprise Ph3)
  - parent_tenant_id  UUID nullable FK → tenants.id   (FR59, Enterprise Fédéré Ph3)

kernel.organization_members:
  - department_ids    UUID[] default []                (FR60, Enterprise Ph3)

kernel.tenant_modules:
  - department_id     UUID nullable                    (FR61, Enterprise Ph3)

shared.contacts:
  - linked_tenant_id  UUID nullable                    (FR53, Connect Ph3)

shared.catalog_items:
  - supplier_reference UUID nullable                   (FR54, Connect Ph3)

shared.transactions (transaction_type enum):
  - Add 'transfer_inter_tenant' to transaction_type enum
                                                       (FR55, Connect Ph3)

**Given** each new column is created
**When** existing rows are read
**Then** all nullable fields return null, boolean fields return false,
enum fields return 'standalone' — zero breaking change for 3 existing clients

**Given** RLS is active on kernel.tenants
**When** the new fields are queried
**Then** existing RLS policies cover them automatically (no new RLS
policy needed — same tenant_id filter applies)

**Given** the migration completes
**Then** each field has a comment in the Prisma schema explaining its
phase and purpose, e.g.:
  /// Phase 2b — Programme Ambassadeurs. Populated when tenant is created
  /// via referral. FK to tenants.id.
  referred_by String? @db.Uuid
```

**Rationale:** One dedicated migration prevents Phase 3 DB fields from being scattered across Epics 2–5 where they would be easy to miss. Nullable columns with safe defaults cost nothing but guarantee no breaking migration at Phase 3 launch.

---

### A4+A5 — `epics.md` New Epics 10–13 + FR Coverage Map

**Epic list updates (insert/modify):**

- Epic 8 FRs: add FR58, FR75
- Epic 9 FRs: change FR52→FR56, FR53→FR57
- Add Epics 10, 11, 12, 13 (see Section 3 for summaries)

**FR Coverage Map updates:**

| FR | Epic/Story | Description |
|:---|:---|:---|
| FR52 (DB) | Story 1.6 | tenants: referred_by + network_visible |
| FR53 (DB) | Story 1.6 | contacts: linked_tenant_id |
| FR54 (DB) | Story 1.6 | catalog_items: supplier_reference |
| FR55 (DB) | Story 1.6 | transaction type: transfer_inter_tenant |
| FR56 | Epic 9 | Zero-loss data migration (was FR52 in v1) |
| FR57 | Epic 9 | Prisma multi-schema (was FR53 in v1) |
| FR58 | Epic 8 | Module-agnostic sync adapters (was FR54 in v1) |
| FR59 (DB) | Story 1.6 | tenants: org_mode + parent_tenant_id |
| FR60 (DB) | Story 1.6 | organization_members: department_ids |
| FR61 (DB) | Story 1.6 | tenant_modules: department_id |
| FR62 | Epic 13 | Inter-department events via event bus |
| FR63–FR68 | Epic 13 | RH & Paie Enterprise (CNSS, CARFO, bulletins) |
| FR69–FR72 | Epic 13 | Comptabilité OHADA (plan comptable, clôture, FEC) |
| FR73–FR74 | Epic 13 | Import Enterprise + Retail → Enterprise migration |
| FR75 | Epic 8 | Gestion des Échecs de Sync (outbox lifecycle) |

---

### A6 — `docs/architecture-scalario-2026-03-08.md` : 6 targeted updates

**A6.1 — Section 1: Architectural Drivers**
- Fix: `FR52-FR54` → `FR56-FR58` in row #6
- Add row #8: Multi-Phase Product Expansion (FR52–FR55, FR59–FR75) — DB anticipation, org_mode, zero breaking migration at Phase 3 launch

**A6.2 — Section 2: High-Level Architecture**
- Add note block after diagram documenting SDUI (Epic 10), Connect (Epic 12), Enterprise (Epic 13) as planned future architecture layers

**A6.3 — Section 5: Data Architecture (Prisma schema)**
- Add Phase 3 anticipation fields to tenants, organization_members, tenant_modules, shared.contacts, shared.catalog_items models with `///` comments explaining phase and purpose

**A6.4 — Section 12: FR Traceability**
- Fix rows FR52→FR56, FR53→FR57, FR54→FR58
- Add rows FR52(DB)–FR75 with components and schemas
- Update coverage: `54/54` → `75/75`

**A6.5 — Section 13: NFR Traceability**
- Split NFR20 into two rows: Retail (≤10/≤20 users) and Enterprise (≤50 users, 4 departments)
- Update coverage note to reflect dual NFR20/NFR21/NFR22 targets

**A6.6 — Section 14: Trade-offs & Decisions**
- Add Decision N: Server-Driven UI (Layout-as-Data) — rationale, trade-offs, timing (Epic 10 after Epic 6)

---

## Section 5: Implementation Handoff

**Scope Classification: Major** — fundamental addition of 3 product dimensions and 21 FRs. However, Phase 1 execution is unaffected beyond 2 story edits + 1 new story.

### Immediate Actions (before Story 1.2 starts)

| Priority | Action | Who | Artifact |
|:---|:---|:---|:---|
| 🔴 BLOCKING | Apply A1: Edit Story 1.2 (RBAC roles + guard note) | Developer | `epics.md` |
| 🔴 BLOCKING | Apply A2: Edit Story 1.3 (module registry seed + guard) | Developer | `epics.md` |
| 🔴 BLOCKING | Apply A3: Add Story 1.6 (Phase 3 DB migration) | Developer | `epics.md` |

### Before Sprint Planning (next sprint)

| Priority | Action | Who | Artifact |
|:---|:---|:---|:---|
| 🟡 REQUIRED | Apply A4+A5: Add Epics 10–13 + FR Coverage Map | Developer | `epics.md` |
| 🟡 REQUIRED | Apply A6.1–A6.6: Update architecture doc | Developer | `architecture-scalario-2026-03-08.md` |

### Success Criteria

- [ ] `epics.md` FR Coverage Map shows 75/75 FRs mapped (was 54/54)
- [ ] Story 1.6 exists in Epic 1 with all 10 DB anticipation fields specified
- [ ] Story 1.2 seed includes DepartmentAdmin + Employee roles (phase3 metadata)
- [ ] Story 1.3 seed includes connect + enterprise modules (available_phase3)
- [ ] Architecture doc FR Traceability shows 75/75
- [ ] Architecture doc has SDUI ADR in Trade-offs section
- [ ] Epic sequence documented: 1→2→3→4→5→6→10→7→8→9→11→12→13

### Handoff Recipients

- **Development team (direct implementation):** A1, A2, A3 — apply immediately to unblock Story 1.2
- **Architecture review (solo — Carlos-simpore):** A6 — update architecture doc before Epic 10 starts
- **Sprint planning:** A4+A5 — complete epic list before next sprint planning session

---

*Generated by BMAD Correct Course workflow — 2026-03-13*
