# Scalario Conventions

## Naming Conventions

### Layers
- Kernel: `src/kernel/[service]/`
- Shared module: `src/modules/[module-name]/`
- Vertical adapter: `src/verticals/[vertical]/`
- Vertical sub-type: `src/verticals/[vertical]/sub-types/[sub-type]/`

### Frontend (Flutter)
- Kernel features: `lib/core/[feature]/`
- Shared module features: `lib/features/[module_name]/`
- Vertical features: `lib/verticals/[vertical]/`

### Database Tables
- Kernel: `tenants`, `users`, `roles`, `permissions`, `tenant_modules`
- Shared modules: `[module]_[entity]` → `stock_products`, `sales_orders`, `cash_sessions`
- Vertical: `[vertical]_[entity]` → `retail_transfers`, `retail_loss_declarations`

### Events
- `[module].[entity].[action]` → `stock.level.critical`, `sales.order.completed`
- Vertical events: `[vertical].[entity].[action]` → `retail.transfer.validated`

### API Routes
```
/api/v1/kernel/[resource]         → /api/v1/kernel/tenants
/api/v1/[module]/[resource]       → /api/v1/stock/products
/api/v1/[vertical]/[resource]     → /api/v1/retail/transfers
```

## Entity Base Fields

Every entity MUST extend BaseEntity:

```typescript
export abstract class BaseEntity {
  id: string;           // UUID, auto-generated
  tenantId: string;     // UUID, mandatory, indexed, RLS
  createdBy: string;    // UUID, FK → users
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;  // soft delete
  syncVersion: number;     // delta sync, incremented on every write
}
```

No exceptions. Even "small" lookup tables get tenant_id and soft delete.

## Backend Conventions (NestJS)

### Service Method Pattern

```
validate → authorize → execute → persist → emit events → return
```

Every service method follows this exact order. Do not skip steps.

### Guard Stack (every endpoint)

```
JwtAuthGuard → TenantGuard → ModuleActiveGuard → RbacGuard
```

- `JwtAuthGuard`: Verifies Supabase JWT
- `TenantGuard`: Extracts tenant context, injects TenantContext into request
- `ModuleActiveGuard`: Checks this module is activated for the tenant
- `RbacGuard`: Checks user's role has the required permission for this action

### TenantContext (injected by TenantGuard)

```typescript
interface TenantContext {
  tenantId: string;
  userId: string;
  orgId: string;
  verticalType: string;       // 'retail-grocery'
  activeModules: string[];    // ['stock', 'sales', 'cash']
  permissions: Permission[];
  locationId?: string;        // for multi-location tenants
  timezone: string;
  currency: string;
}
```

### DTO Validation

Use `class-validator`. Be strict — these are non-tech users, inputs will be messy:

```typescript
export class CreateProductDto {
  @IsString()
  @MinLength(2)
  @MaxLength(200)
  name: string;

  @IsEnum(UnitType)
  unitType: UnitType;  // 'piece', 'kg', 'litre', 'sachet'

  @IsNumber()
  @Min(0)
  sellingPrice: number;

  @IsUUID()
  categoryId: string;
}
```

### Error Codes

```typescript
throw new BadRequestException({
  code: 'STOCK_INSUFFICIENT_QUANTITY',
  message: 'Quantité insuffisante en stock',  // French for Francophone Africa clients
  module: 'stock',
  details: { available: 5, requested: 10 },
});
```

Error messages should be in French (primary user base is Francophone West Africa).

## Frontend Conventions (Flutter)

### Repository Pattern (mandatory)

```dart
// Abstract (domain layer)
abstract class ProductRepository {
  Future<Product> create(CreateProductParams params);
  Stream<List<Product>> watchByCategory(String categoryId);
}

// Implementation (data layer) — ALWAYS local-first
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remote;
  final ProductLocalDataSource local;
  final SyncService sync;

  @override
  Future<Product> create(CreateProductParams params) async {
    // 1. Write to local DB
    final product = await local.insert(params);
    // 2. Queue for background sync
    await sync.enqueue(OutboxEntry.create('stock', 'product', product));
    return product;
  }
}
```

### Offline-First UI Rules

1. UI ALWAYS reads from local DB (streams/reactive)
2. Writes go to local DB first, then Outbox
3. Show sync status: ✓ synced, ↻ pending, ✗ failed
4. Never block user action on network availability
5. Cash payment always works offline. Mobile money requires online.

### UX for Non-Tech Users

- Buttons: minimum 48px touch target, clear labels in French
- Confirmations: always confirm before delete, close session, or validate receiving
- Numbers: use large numpad for quantity/price entry, not keyboard
- Navigation: maximum 2 taps to reach any frequent action
- Feedback: success = green toast, error = red dialog with simple explanation
- No technical jargon in UI — "Synchronisation en cours" not "Syncing outbox queue"

### Module-Aware Navigation

```dart
// Only show activated modules for this tenant
final modules = ref.watch(activeModulesProvider);
final vertical = ref.watch(verticalTypeProvider);

// NavigationRail adapts to tenant's active modules
// Vertical-specific screens only show for matching vertical
```

## Database Conventions (Supabase)

### RLS — Mandatory on Every Table

```sql
ALTER TABLE [table] ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tenant_isolation" ON [table]
  USING (tenant_id = (current_setting('app.current_tenant'))::uuid);
```

### Migrations

```
supabase/migrations/
  [timestamp]_kernel_[action]_[table].sql
  [timestamp]_[module]_[action]_[table].sql
  [timestamp]_[vertical]_[action]_[table].sql

Examples:
  20240115_kernel_create_tenants.sql
  20240120_stock_create_products.sql
  20240125_retail_create_transfers.sql
```

## Story Conventions

### Story ID Format

```
KERNEL-001: Description
STOCK-001: Description
SALES-001: Description
CASH-001: Description
RETAIL-001: Description (vertical-specific)
```

### Every Story Must Specify

1. **Target layer:** kernel / shared module / vertical adapter
2. **Offline support:** full / partial (read-only) / online-only
3. **Roles involved:** which roles can perform this action
4. **Multi-tenant check:** confirms tenant isolation is maintained

## Git Conventions

### Branches
```
feature/kernel/KERNEL-001-description
feature/stock/STOCK-001-description
feature/retail/RETAIL-001-description
fix/sales/SALES-042-description
refactor/kernel/description
```

### Commits
```
kernel: implement tenant context guard
stock: add product entity and migration
stock: implement movement recording service
retail: add grocery shrinkage extension
retail: implement transfer validation workflow
flutter/stock: product list screen with offline support
flutter/sales: POS numpad and cart panel
```

## Localization

- Primary language: **French** (Francophone West Africa target market)
- Secondary: English
- All user-facing strings must be externalized for i18n
- Error messages default to French
- Currency: default XOF (CFA Franc), configurable per tenant
- Date format: DD/MM/YYYY (European/African convention)
- Number format: 1.000,00 (dot for thousands, comma for decimals)
