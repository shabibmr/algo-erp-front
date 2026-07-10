# algoERP Backend — API Contract

> Source: `src/core/types/index.ts`, `src/core/middleware/*`, `src/core/auth/*`,
> `src/core/errors/AppError.ts`, `src/core/repository/BaseRepository.ts`,
> `src/core/utils/decimal.ts`, `src/modules/inventory/*` (Brand), `src/modules/transactions/*`
> (SalesInvoice). Every shape below is quoted or paraphrased directly from that source —
> nothing here is invented.

---

## 1. Response envelope (exact types, `src/core/types/index.ts`)

```ts
export interface ApiResponse<T> {
  success: boolean;
  message?: string;
  data?: T;
  error?: {
    message: string;
    code?: string;
    details?: any;
  };
  requestId?: string;
}

export interface Paginated<T> {
  items: T[];
  meta: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}
```

- **Success response**: `{ success: true, message?, data, requestId }`. `data` is either a
  bare object/array or a `Paginated<T>` (`{ items, meta }`) for list endpoints.
- **Error response** (built in `src/core/middleware/errorHandler.ts`):
  ```ts
  { success: false, error: { message: string, details?: any }, requestId: string }
  ```
  `error.code` is declared in the type but **not actually populated anywhere in
  `errorHandler.ts`** — only `message` and (for `ValidationError`) `details` are set. Do
  not rely on `error.code` being present.
- **Pagination metadata** is always `{ total, page, limit, totalPages }` — computed as
  `Math.ceil(total / limit)` in `BaseRepository.findMany` (and independently, identically,
  in `voucherRead.service.ts`'s `paginateMeta()`).
- List query params actually read: `page`, `limit` (both parsed with `Number(req.query.x)`,
  no validation beyond that in most controllers; the voucher-read module clamps
  `page = Math.max(1, page||1)`, `limit = Math.min(200, Math.max(1, limit||20))`).

### HTTP status codes used (from `AppError` subclasses, `src/core/errors/AppError.ts`)

| Error class | Status | Used for |
|---|---|---|
| `ValidationError` | 400 | Zod validation failures (auto-mapped from `ZodError` in `errorHandler.ts`), business-rule validation (e.g. discount exceeds max) |
| `BadRequestError` | 400 | Generic bad request |
| `UnauthorizedError` | 401 | Missing/invalid/expired JWT, bad login credentials |
| `ForbiddenError` | 403 | RBAC denial (`authorize()` middleware) |
| `NotFoundError` | 404 | Missing entity |
| `ConflictError` | 409 | Uniqueness violations (e.g. duplicate Brand name), invalid state transitions (e.g. cancel an already-cancelled voucher) |
| *(unhandled/system error)* | 500 | Generic message `"An unexpected error occurred. Please contact support."`; the real error is also written to the `error_reporting` table server-side and logged, never leaked to the client |

Successful creates return **201**; most other successful operations return **200**.

---

## 2. Auth flow (`src/core/auth/auth.controller.ts`, `auth.routes.ts`)

All routes mounted at `/auth`, rate-limited (15 min window, max 30 requests) via
`authLimiter` in `app.ts`.

### `POST /auth/login` (public)

Request:
```ts
{ username: string /* min 1 */, password: string /* min 1 */ }
```
Logic: looks up `user_credentials` by `username`, requires `is_active`, verifies password
hash, resolves `companyId` from the user's `branch_id → branch.company_id` (falling back to
`companyprofile.findFirst()` if that fails), issues JWT pair, updates `last_login_at`, writes
an `AuditLog` LOGIN row (SUCCESS or FAILURE).

Response (`data`):
```ts
{
  accessToken: string;
  refreshToken: string;
  user: {
    id: number;
    username: string;
    roleId: number;
    roleName: string;
    branchId: number | null;
    companyId: number | null;
  };
}
```

### `POST /auth/refresh` (public)

Request: `{ refreshToken: string }`. Verifies the refresh token, re-checks the user is still
`is_active`, re-signs a **new** access + refresh token pair (rotation).

Response (`data`): `{ accessToken: string; refreshToken: string }`.

### `GET /auth/me` (requires `Authorization: Bearer`)

Response (`data`):
```ts
{
  id: number;
  username: string;
  roleId: number;
  roleName: string;
  branchId: number | null;
  companyId: number | null;   // from req.user (JWT claim), not re-resolved from DB
  lastLoginAt: Date | null;
}
```

### `POST /auth/change-password` (requires auth)

Request: `{ currentPassword: string /* min 1 */, newPassword: string /* min 6 */ }`. Verifies
current password, hashes and stores the new one. No token invalidation logic observed —
existing tokens remain valid until natural expiry.

Response: `{ success: true, message: 'Password changed successfully', requestId }` (no `data`).

### `POST /auth/logout` (requires auth)

Writes a LOGOUT audit row. **No server-side token/session invalidation** — this is a
client-side/audit-only logout (no token blacklist observed anywhere in the codebase).

Response: `{ success: true, message: 'Logged out successfully', requestId }`.

---

## 3. JWT payload / `AuthUser` shape

```ts
export interface AuthUser {
  userId: number;
  username: string;
  roleId: number;
  branchId: number | null;
  companyId: number | null;
}
```
This is exactly what `authenticate` middleware (`src/core/middleware/authenticate.ts`)
decodes from the access token into `req.user`, and also seeds `req.tenant` from
`user.companyId`/`user.branchId` at that point.

---

## 4. Tenancy resolution (`src/core/middleware/tenantContext.ts` + `authenticate.ts`)

- If the request is authenticated, `authenticate` sets
  `req.tenant = { companyId: user.companyId, branchId: user.branchId }` **from the JWT
  claims** — this happens before `tenantContextMiddleware` runs.
- `tenantContextMiddleware` runs globally (mounted before route handlers) and **only**
  populates `req.tenant` from the `X-Company-Id` / `X-Branch-Id` headers **if `req.tenant`
  is not already set** (i.e. unauthenticated routes, or any route where `authenticate` was
  not applied). Header parsing: `Number(header)`, `NaN` coerced to `null`.
- **Net effect: for any authenticated request, the JWT's `companyId`/`branchId` always wins;
  `X-Company-Id`/`X-Branch-Id` headers are only honored when there is no JWT-derived tenant
  context (effectively: never, on any route that requires `authenticate`, which is all
  business routes in this backend).** The Flutter client should still send the headers for
  forward-compatibility/defensive reasons, but must not expect them to override the token's
  company/branch.
- `scopeTenant(where, tenant, fields)` helper injects `company_id`/`branch_id` into a Prisma
  `where` clause **only for fields explicitly passed in** — it is not automatically applied
  to every query; each repository/service must opt in. **Most master tables observed
  (ledgers, items, brands, etc.) have no `company_id`/`branch_id` column at all** — per
  `BACKEND_CONTEXT.md` §3.4, these masters are effectively global/shared across tenants in
  this schema, not per-company. Only `Branch`, `FinancialYear`, `VoucherSeries`,
  `CurrencyRate` (via `financial_year_id`) carry a `company_id` column.

---

## 5. `X-Request-Id` handling (`src/core/middleware/requestId.ts`)

```ts
const requestId = (req.headers['x-request-id'] as string) || crypto.randomUUID();
req.requestId = requestId;
res.setHeader('X-Request-Id', requestId);
```
- If the client sends `X-Request-Id`, it is **echoed back verbatim** (both as the response
  header and inside every `ApiResponse.requestId`). If omitted, the server mints a UUID v4.
- This is a pure echo/log-correlation mechanism — it is **not** used anywhere as an
  idempotency key (see `offline-sync-readiness.md`).

---

## 6. RBAC model (verbatim from code)

### 6.1 Mechanism

`authorize(moduleName, action)` (`src/core/middleware/authorize.ts`) is applied per-route.
It queries `user_access_permissions` for `{ role_id: req.user.roleId, module_name:
moduleName }`, maps `action` to a column (`create→Allow_Create`, `read→Allow_Read`,
`update→Allow_Update`, `delete→Allow_Delete`, `share→Allow_Share`), and denies (403) if no
row exists or the flag is falsy. Results are cached per-role in an in-process
`Record<roleId, Record<moduleName, Record<action, boolean>>>` map (cleared via
`clearPermissionCache(roleId?)`; no automatic TTL — a permission change requires an explicit
cache-clear call or process restart to take effect for already-cached roles).

```ts
export type PermissionAction = 'create' | 'read' | 'update' | 'delete' | 'share';
```

### 6.2 Full list of `module_name` values used across `authorize()` calls (real, grepped from every `*.routes.ts`)

`CompanyProfile`, `FinancialYear`, `Branch`, `Currency`, `CurrencyRate`, `VoucherSeries`,
`AddressBook`, `ConfigSetting`, `ExtraValues`, `AuditLog`, `UserRole`, `UserAccessPermission`,
`UserCredentials`, `ProjectMaster`, `ErrorReporting`, `Accounts`, `Employee`, `Inventory`,
`Transactions`, `SalesInvoice`, `PurchaseInvoice`, `PaymentVoucher`, `ReceiptVoucher`,
`ContraVoucher`, `JournalVoucher`, `CreditNote`, `DebitNote`, `Quotation`, `SalesOrder`,
`PurchaseOrder`, `GodownTransfer`, `DeliveryNote`, `ReceiptNote`, `MaterialIn`,
`Requirement`, `StockRequest`, `JournalLedger`, `TermsAndConditions`,
`TransportationDetails`.

Note the split: **Accounts, Inventory, Employee are coarse single-module gates** covering
dozens of sub-entities each; **Organization and Transactions are fine-grained**, one module
per entity/voucher-type. See `feature-inventory.md` for exactly which module gates which
route.

### 6.3 Action set

Fixed 5: `create`, `read`, `update`, `delete`, `share` (`share` is defined in the schema/type
but **no route in any `*.routes.ts` file was found calling `authorize(x, 'share')`** — it is
provisioned but currently unused by the API surface).

---

## 7. Soft-delete convention

- Standard pattern: `is_active: Boolean @default(true)` column; `BaseRepository` defaults
  `softDeleteField: 'is_active'` and its `delete()` method does `UPDATE ... SET is_active =
  false` unless `hardDelete: true` is passed or the repository is configured with
  `softDeleteField: null`.
- **Confirmed exceptions with `softDeleteField: null` (real hard delete)**: `brands`
  (`BrandRepository` in `inventory.repository.ts`, `softDeleteField: null` +
  `BrandService.deleteBrand` calls `.delete(id, { hardDelete: true })`); the same repository
  file follows this pattern for `category` and other tables that lack an `is_active` column
  in `schema.prisma` (`account_groups`, `ledger_bank_details`, `ledger_credit_settings`,
  `ledger_tax_settings`, `uom_conversion`, `pricelist_entries`, etc.).
- Default reads exclude inactive rows (`applySoftDelete` adds `{ is_active: true }` to the
  `where` clause) unless the caller passes `includeInactive: true` — but **whether any given
  controller actually exposes an `includeInactive` query param is per-entity**; this was not
  confirmed to be wired through uniformly to the HTTP layer for every list endpoint, so treat
  "include inactive" as a repository capability, not a guaranteed public query parameter.

---

## 8. Decimal / money serialization convention

- Prisma `Decimal` columns (e.g. `currencyrates.buy_rate`, `ledger_credit_settings.credit_limit`,
  `item_batches.cost_price`) surface as Prisma's `Prisma.Decimal` objects server-side.
  `src/core/utils/decimal.ts` provides `toDecimal/add/sub/mul/div/round/sum/isEqual/isZero`
  wrappers used throughout the posting engine to avoid binary-float math.
- **Important inconsistency for the client to handle**: not everything monetary is a
  `Decimal` column. Many legacy tables use plain `Float` (e.g. `sales_invoice_details.Price`,
  `sales_invoice_main.Total`, `ledger_master.Closing_Balance`, `sales_inventory_items.Price`)
  and at least one, `ledger_master.Opening_Balance`, is stored as a **`String`**. When Prisma
  serializes a response to JSON, `Decimal` values become strings (Prisma's default JSON
  serialization of `Decimal` is a numeric string, e.g. `"1234.50"`) while `Float` columns
  serialize as native JSON numbers. **The Flutter client must not assume one uniform numeric
  wire type for money fields — decode defensively (accept both JSON number and numeric
  string) per field**, and treat `ledger_master.Opening_Balance` specifically as a string
  that must be parsed.
- The voucher-posting engine internally rounds to 2 decimal places (`round(val, 2)`) for
  discount/tax/round-off math; see `feature-inventory.md` §5.2.

---

## 9. Representative Master entity — Brand

### 9.1 Prisma model (`prisma/schema.prisma`)

```prisma
model brands {
  id                    Int                     @id @default(autoincrement())
  Brand_Name            String                  @unique(map: "uk_brand_name") @db.VarChar(150)
  Brand_Description     String?                 @db.VarChar(2000)
  created_at            DateTime                @default(now()) @db.Timestamp(0)
  updated_at            DateTime?               @db.Timestamp(0)
  Last_Modified         DateTime?               @default(now()) @db.Timestamp(0)
  sales_inventory_items sales_inventory_items[]
}
```

### 9.2 Zod request schema (`src/modules/inventory/inventory.schema.ts`)

```ts
export const brandSchema = z.object({
  body: z.object({
    Brand_Name: z.string().min(1).max(150),
    Brand_Description: z.string().max(2000).optional().nullable(),
  }),
});
```
Same schema is used for both `POST /inventory/brand` and `PUT /inventory/brand/:id`.

### 9.3 Endpoints & behavior (`inventory.controller.ts` + `inventory.service.ts`, `BrandService`)

| Method | Path | RBAC | Notes |
|---|---|---|---|
| GET | `/inventory/brand` | `Inventory:read` | `?page&limit` → `Paginated<brand>` |
| GET | `/inventory/brand/:id` | `Inventory:read` | 404 if not found |
| POST | `/inventory/brand` | `Inventory:create` | 409 `ConflictError('Brand name already exists')` if `Brand_Name` already taken; 201 on success, `message: 'Brand created successfully'` |
| PUT | `/inventory/brand/:id` | `Inventory:update` | Same uniqueness re-check only if `Brand_Name` is being changed |
| DELETE | `/inventory/brand/:id` | `Inventory:delete` | **Hard delete** (`hardDelete: true`) — irreversible, no tombstone left in `brands` |

### 9.4 Response shapes

`GET /inventory/brand` → `data`:
```ts
{
  items: Array<{
    id: number;
    Brand_Name: string;
    Brand_Description: string | null;
    created_at: string;      // ISO datetime
    updated_at: string | null;
    Last_Modified: string | null;
  }>;
  meta: { total: number; page: number; limit: number; totalPages: number };
}
```

`POST /inventory/brand` → `data`: the created row (same shape as one `items[]` element).

---

## 10. Representative Voucher-document — SalesInvoice

### 10.1 Request schema for posting (`src/modules/transactions/transactions.schema.ts`)

```ts
export const salesInvoiceLineSchema = z.object({
  item_id: z.number().int().positive(),
  sku_id: z.number().int().optional().nullable(),
  batch_id: z.number().int().optional().nullable(),
  quantity: z.number().positive(),
  price: z.number().nonnegative(),
  discount_percent: z.number().min(0).max(100).default(0),
  tax_rate: z.number().min(0).max(100).default(0),
});

export const salesInvoicePostSchema = z.object({
  body: z.object({
    voucher_prefix: z.string().min(1).max(50),
    voucher_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),   // YYYY-MM-DD
    financial_year: z.string().min(4).max(10),
    customer_ledger_id: z.number().int().positive(),
    godown_id: z.number().int().positive(),
    salesperson_employee_id: z.number().int().optional().nullable(),
    voucher_project_id: z.number().int().optional().nullable(),
    billing_name: z.string().max(100).optional().nullable(),
    narration: z.string().max(2000).optional().nullable(),
    credit_days: z.number().int().nonnegative().default(30),
    lines: z.array(salesInvoiceLineSchema).min(1),
    source_voucher_id: z.number().int().optional().nullable(),   // for Quotation/SO→Invoice conversion
    source_voucher_type: z.string().max(50).optional().nullable(),
  }),
});
```

### 10.2 `POST /transactions/sales-invoice` — response (`VoucherPostingService.postSalesInvoice`, real return statement)

```ts
// data:
{
  id: number;          // voucher_headers.id (same PK as sales_invoice_main.id)
  voucherNo: string;    // e.g. "SI/00001" per VoucherSeries formatting
  total: number;        // gross total (subtotal - discount + tax), rounded to 2dp
  subtotal: number;
  discount: number;
  vat: number;
}
```
Status **201**, `message: 'Sales invoice posted successfully'`.

What actually happens server-side in this one call (verified in
`voucherPosting.service.ts`): resolves `customer_ledger_id` (404 if missing) → generates
voucher number via `TransactionHelperService` → creates `voucher_headers` row → computes
per-line subtotal/discount/tax with `Prisma.Decimal` math → creates `sales_invoice_main`
(`VoucherStatus: 'Posted'` directly — no Draft stage for this endpoint) → bulk-inserts
`sales_invoice_details` → resolves `SALES_LEDGER_ID`/`TAX_LEDGER_ID` from `ConfigSetting` →
asserts `Σdebit === Σcredit` in application code → inserts `journal_ledger` rows (Dr
Customer, Cr Sales, Cr VAT if >0) → inserts `stock_ledger` rows (`quantity_out` per line,
`quantity_in` always 0) → inserts one `billwise_records` row (`RefType: 'New Ref'`,
`Due_Date` computed from `credit_days`) → optionally inserts a `voucherlinkage` row if
`source_voucher_id` was supplied → writes an `AuditLog` APPROVE row — all inside one
`prisma.$transaction`.

### 10.3 `GET /transactions/sales-invoices` — list (`SalesInvoiceReadService.list`, real code)

Query params: `start_date`, `end_date`, `prefix`, `financial_year`, `ledger_id`, `status`,
`page`, `limit`.

```ts
// data:
{
  items: Array<{
    // voucher_headers row
    id: number;
    voucher_type: 'SalesInvoice';
    voucher_prefix: string;
    voucher_no: string;
    voucher_date: string;
    created_at: string;
    updated_at: string | null;
    // nested include
    sales_invoice_main: {
      id: number;
      godown_id: number | null;
      voucher_ledger_id: number | null;
      Billing_Name: string | null;
      Total: number | null;
      Gross_Total: number | null;
      Vat_Amount: number | null;
      VoucherStatus: string | null;   // Draft|Approved|Posted|Cancelled|Rejected
      Voucher_No_Display: string | null;
      // ...remaining sales_invoice_main columns, see feature-inventory.md
    } | null;
  }>;
  meta: { total: number; page: number; limit: number; totalPages: number };
}
```

### 10.4 `GET /transactions/sales-invoices/:id` — detail (`SalesInvoiceReadService.getById`, real code)

```ts
// data: spread of sales_invoice_main (with nested voucher_headers) + details[]
{
  id: number;
  ...all sales_invoice_main columns...,
  voucher_headers: { id, voucher_type, voucher_prefix, voucher_no, voucher_date, created_at, updated_at };
  details: Array<{
    id: number; voucher_id: number; item_id: number | null; voucher_sku_id: number | null;
    Quantity: number; Price: number; Discount_Percent: number | null; Discount_Amount: number | null;
    Subtotal: number | null; Tax_Rate: number | null; Tax_Amount: number | null;
    ItemVoucherStatus: number | null;   // 0=Pending,1=Active,2=Completed,3=Cancelled
    itemProductionStatus: number | null;
    // sales_invoice_details has NO updated_at/created_at column at all
  }>;
}
```
404 `NotFoundError('SalesInvoice #<id> not found')` if the main row does not exist.

### 10.5 Lifecycle actions on this voucher (generic, `voucherLifecycle.routes.ts`, type=`SalesInvoice`)

`PUT /transactions/SalesInvoice/:id` (edit, Draft only), `POST
/transactions/SalesInvoice/:id/cancel` (reverses GL+stock), `POST
/transactions/SalesInvoice/:id/approve`, `POST /transactions/SalesInvoice/:id/reject` — all
gated by `Transactions:update`, not `SalesInvoice:update` (the lifecycle routes use the
coarse `Transactions` module regardless of voucher type).
