# Scalario ERP Architecture — Multi-Vertical Modular Design

## Three-Layer Architecture

```
┌─────────────────────────────────────────────────┐
│ Layer 3: VERTICAL ADAPTERS                      │
│ Domain-specific extensions and configurations   │
│ Depends on: Layer 2 (shared modules)            │
├─────────────────────────────────────────────────┤
│ Layer 2: SHARED BUSINESS MODULES                │
│ Reusable business logic across verticals        │
│ Depends on: Layer 1 (kernel) only               │
├─────────────────────────────────────────────────┤
│ Layer 1: KERNEL                                 │
│ Infrastructure, auth, tenancy, events, sync     │
│ Depends on: nothing (foundation)                │
└─────────────────────────────────────────────────┘
```

**Iron rule:** Dependencies flow DOWN only. A vertical adapter can import from shared
modules and kernel. A shared module can import from kernel. Nothing imports from a
vertical adapter. Nothing in kernel imports from shared modules.

## Layer 1: Kernel (@scalario/kernel)

```
src/kernel/
├── auth/              # Supabase JWT verification, session management
├── tenant/            # Tenant CRUD, TenantGuard, tenant context injection
│   └── tenant.entity  # id, name, vertical_type, config, active_modules[]
├── org/               # Organization: locations, departments
├── user/              # User profiles, role assignments
├── rbac/              # Role-based access control engine
│   └── permission.entity  # module, action, role → allow/deny
├── plugin-registry/   # Module activation per tenant
│   └── tenant_modules.entity  # tenant_id, module_id, config, activated_at
├── event-bus/         # EventEmitter2 wrapper for domain events
├── sync/              # Outbox queue, delta sync engine, conflict resolution
├── notification/      # Push notifications, WhatsApp integration, email
├── common/            # Base entity, shared DTOs, decorators, pipes
└── config/            # App config, feature flags per tenant
```

### Tenant Entity (Critical)

```typescript
@Entity('tenants')
export class Tenant extends BaseEntity {
  @Column()
  name: string;

  @Column()
  verticalType: string;  // 'retail-grocery', 'retail-cosmetics', 'pharmacy', etc.

  @Column()
  verticalSubType: string;  // more specific classification

  @Column('jsonb', { default: {} })
  verticalConfig: Record<string, any>;  // vertical-specific settings

  @Column('simple-array')
  activeModules: string[];  // ['stock', 'sales', 'cash', 'purchasing']

  @Column()
  timezone: string;  // important for daily closings

  @Column()
  currency: string;  // XOF, EUR, USD...

  @Column()
  country: string;
}
```

### RBAC Model

Permissions are scoped per module and defined by the vertical adapter:

```
Permission = (module, action, role) → allow/deny

Example for retail-grocery:
  (stock, view,        proprietaire)  → allow
  (stock, view,        gestionnaire)  → allow
  (stock, view,        commercial)    → allow (own location only)
  (stock, receive,     gestionnaire)  → allow
  (stock, receive,     commercial)    → deny
  (sales, sell,        commercial)    → allow
  (sales, sell,        gestionnaire)  → deny
  (cash,  close_day,   proprietaire)  → allow
  (cash,  close_day,   gestionnaire)  → allow
  (cash,  close_day,   commercial)    → deny
  (stock, modify_price, proprietaire) → allow
  (stock, modify_price, gestionnaire) → deny
  (stock, modify_price, commercial)   → deny
```

The vertical adapter provides a **default role template** that gets copied when
a new tenant is created. The owner can then customize.

## Layer 2: Shared Business Modules

### @scalario/stock — Inventory Management

Handles: products, categories, stock levels, movements, alerts.

```
src/modules/stock/
├── entities/
│   ├── product.entity.ts          # id, tenant_id, name, sku, category, unit_type
│   ├── product-variant.entity.ts  # size, color, weight variants
│   ├── stock-level.entity.ts      # product_id, location_id, quantity, min_threshold
│   ├── stock-movement.entity.ts   # product_id, type(in/out/transfer/loss), quantity, reason
│   └── category.entity.ts
├── services/
│   ├── stock.service.ts           # CRUD, level checks, threshold alerts
│   ├── movement.service.ts        # Record movements, update levels
│   └── stock-events.service.ts    # Emit: stock.level.critical, stock.movement.recorded
├── extension-points/              # Hooks for vertical adapters
│   ├── stock-extension.interface.ts
│   └── README.md
```

**Extension Points for Vertical Adapters:**

```typescript
// Vertical adapters implement this to add custom behavior
interface StockExtension {
  // Called after a product is created — add vertical-specific fields
  onProductCreated?(product: Product, verticalConfig: any): Promise<void>;

  // Called before stock level comparison — adjust for natural loss
  adjustExpectedQuantity?(product: Product, expected: number): number;

  // Called to get extra columns for stock display
  getExtraDisplayFields?(): DisplayField[];

  // Called to validate vertical-specific business rules
  validateMovement?(movement: StockMovement): ValidationResult;
}
```

### @scalario/sales — Point of Sale

Handles: sales transactions, line items, payments, receipts.

```
src/modules/sales/
├── entities/
│   ├── sale.entity.ts            # id, tenant_id, location_id, cashier_id, total, status
│   ├── sale-item.entity.ts       # sale_id, product_id, quantity, unit_price, subtotal
│   ├── payment.entity.ts         # sale_id, method(cash/mobile/card), amount
│   └── receipt.entity.ts         # sale_id, receipt_number, printed_at
├── services/
│   ├── sales.service.ts          # Create sale, add items, process payment
│   └── sales-events.service.ts   # Emit: sales.order.completed, sales.payment.received
```

### @scalario/cash — Cash Management

Handles: cash register sessions, daily closing, reconciliation.

```
src/modules/cash/
├── entities/
│   ├── cash-session.entity.ts    # id, location_id, opened_by, opened_at, closed_at
│   ├── cash-closing.entity.ts    # session_id, expected_amount, actual_amount, difference
│   └── cash-movement.entity.ts   # session_id, type(sale/expense/adjustment), amount
├── services/
│   ├── cash.service.ts           # Open/close sessions, record movements
│   └── reconciliation.service.ts # Compare sales vs cash, flag discrepancies
```

### @scalario/purchasing — Procurement

Handles: supplier orders, receiving, quality control.

```
src/modules/purchasing/
├── entities/
│   ├── supplier.entity.ts
│   ├── purchase-order.entity.ts
│   ├── receiving.entity.ts       # order_id, received_by, validated_by, notes
│   └── receiving-item.entity.ts  # expected_qty, received_qty, quality_notes
```

### @scalario/reporting — Dashboards & Notifications

Handles: aggregated views, daily summaries, alerts.

```
src/modules/reporting/
├── services/
│   ├── dashboard.service.ts      # Real-time KPIs per tenant
│   ├── daily-summary.service.ts  # End-of-day report generation
│   └── alert.service.ts          # Threshold alerts, anomaly detection
```

## Layer 3: Vertical Adapters

### @scalario/vertical-retail

```
src/verticals/retail/
├── retail.vertical.ts            # VerticalRegistration: modules, roles, config schema
├── sub-types/
│   ├── grocery/
│   │   ├── grocery.config.ts     # Default config: shrinkage rates, freshness tracking
│   │   ├── grocery-stock.extension.ts  # StockExtension: bulk→sachet, shrinkage
│   │   └── grocery-roles.ts     # Default roles: Propriétaire, Gestionnaire, Commercial
│   ├── cosmetics/
│   │   ├── cosmetics.config.ts   # Variants (size, color), expiry tracking
│   │   └── cosmetics-stock.extension.ts
│   └── beverages/
│       ├── beverages.config.ts   # Batch tracking, deposits/consignment
│       └── beverages-stock.extension.ts
├── entities/
│   ├── internal-transfer.entity.ts  # Magasin → Rayon transfers with dual validation
│   ├── loss-declaration.entity.ts   # Responsibility tracking (magasin vs rayon)
│   └── restock-request.entity.ts    # Commercial → Gestionnaire → Propriétaire chain
├── services/
│   └── retail-workflow.service.ts   # The 8-phase flow (Blandine's document)
```

### Vertical Registration Contract

```typescript
interface VerticalRegistration {
  verticalId: string;          // 'retail'
  subTypes: string[];          // ['grocery', 'cosmetics', 'beverages']
  requiredModules: string[];   // ['stock', 'sales', 'cash']
  optionalModules: string[];   // ['purchasing', 'reporting', 'contacts']
  defaultRoles: RoleTemplate[];
  configSchema: JSONSchema;    // Validates verticalConfig in tenant
  stockExtension?: StockExtension;
  // Future: salesExtension, cashExtension, etc.
}
```

## Cross-Module Event Map

```
sales.order.completed
  → stock: decrement quantities
  → cash: record cash movement
  → reporting: update daily totals

stock.level.critical
  → reporting: trigger alert to owner
  → notification: send WhatsApp/push to owner

stock.movement.loss_declared
  → reporting: update loss tracking
  → notification: alert owner with responsibility info

cash.session.closed
  → reporting: generate daily summary
  → notification: send evening report to owner

purchasing.order.received
  → stock: increment quantities (after validation)
```

## Database Schema Conventions

Every table follows:

```sql
CREATE TABLE [module]_[entity] (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  -- domain fields --
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,           -- soft delete
  sync_version BIGINT DEFAULT 0,    -- for delta sync

  CONSTRAINT fk_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

-- RLS mandatory
ALTER TABLE [module]_[entity] ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tenant_isolation" ON [module]_[entity]
  USING (tenant_id = (current_setting('app.current_tenant'))::uuid);

-- Indexes for performance
CREATE INDEX idx_[module]_[entity]_tenant ON [module]_[entity](tenant_id);
CREATE INDEX idx_[module]_[entity]_sync ON [module]_[entity](tenant_id, updated_at);
```

## Offline & Sync Architecture

### What works offline
- POS: create sales, process payments (cash only)
- Stock: view levels, declare losses, record movements
- Transfers: initiate and validate internal transfers

### What requires online
- Reporting dashboards (aggregation)
- User management and role changes
- Supplier order submission
- WhatsApp/push notifications

### Outbox Pattern

```sql
CREATE TABLE sync_outbox (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  module_id VARCHAR(50) NOT NULL,   -- 'stock', 'sales', etc.
  entity_type VARCHAR(100) NOT NULL,
  entity_id UUID NOT NULL,
  action VARCHAR(20) NOT NULL,      -- 'CREATE', 'UPDATE', 'DELETE'
  payload JSONB NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',  -- pending, synced, failed
  retry_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  synced_at TIMESTAMPTZ
);
```

### Conflict Resolution
- **Default:** Server wins (last-write-wins with server timestamp)
- **Sales:** Never overwrite completed sales — append corrections instead
- **Stock levels:** Server recalculates from movements (movements are source of truth)
- **Cash sessions:** Once closed, immutable — corrections via adjustment entries

## Migration Path from Current to Target

### Phase 1: Foundation (Kernel)
- Set up kernel services: auth, tenant, org, user, RBAC, event bus, sync
- Create plugin registry and vertical registration system
- Migrate existing auth/tenant logic into kernel

### Phase 2: Shared Modules
- Build stock, sales, cash modules as independent shared modules
- Define extension points for vertical customization
- No vertical-specific logic in shared modules

### Phase 3: Retail Vertical Adapter
- Implement retail vertical with grocery, cosmetics, beverages sub-types
- Build Blandine's 8-phase workflow as the reference implementation
- Implement extension points (shrinkage, bulk→sachet, freshness codes)

### Phase 4: Frontend Restructure
- Reorganize Flutter app into kernel + module + vertical structure
- Module-aware navigation (show only active modules)
- Vertical-aware UI (show vertical-specific fields and workflows)

### Phase 5: Next Verticals (Future)
- Pharmacy: regulated stock, prescription tracking, expiry enforcement
- School: student management, fee collection, academic tracking
- Enterprise: department hierarchy, procurement workflows, HR basics
