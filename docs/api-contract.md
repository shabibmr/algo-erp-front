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

---

## 11. Desk dashboard (`src/modules/transactions/dashboard.routes.ts`, `dashboard.service.ts`)

Mounted at `/reports`. All three routes gated by `authorize('Transactions', 'read')`.

### 11.1 `GET /reports/dashboard` — single-period snapshot

Query: `start_date`, `end_date` (both `YYYY-MM-DD`, default to the current calendar month),
optional `company_id`, `branch_id`.

```ts
// data:
{
  period: { start_date: Date; end_date: Date };
  sales_count: number;      // voucher_headers count, voucher_type='SalesInvoice'
  purchase_count: number;   // voucher_headers count, voucher_type='PurchaseInvoice'
  cash_position: number;    // journal_ledger debit-credit net, Ledger_Type='Cash'
  bank_position: number;    // journal_ledger debit-credit net, Ledger_Type='Bank'
  top_customers: Array<{ voucher_ledger_id: number; _count: { id: number } }>;  // top 5
}
```

### 11.2 `GET /reports/dashboard/trend` — month-over-month trend (added for desk charts)

Query: `months` (default `6`, clamped `[1, 24]`), optional `company_id`, `branch_id`.

```ts
// data:
{
  points: Array<{
    month: string;           // 'YYYY-MM', oldest first
    sales_count: number;
    purchase_count: number;
    cash_position: number;
    bank_position: number;
  }>;
}
```

Same aggregations as 11.1, bucketed per calendar month, run in parallel server-side
(`DashboardService.getTrend`). No `top_customers` per bucket.

### 11.3 `GET /reports/alerts` — action items

No query params.

```ts
// data:
{
  expiring_documents: Array<{ type: 'document_expiry'; employee: {...} | null; doc_type; expiry_date; days_until_expiry: number | null }>;
  overdue_bills: Array<{ type: 'overdue_bill'; ledger_id: number; ref_no: string; voucher_no: string; due_date: Date | null; amount: number }>;
}
```

### 11.4 `GET /reports/search` — global search autocomplete (`GlobalSearchService.search`)

Query: `q` (string, required — returns all-empty result if omitted or `< 2` chars after trim).

```ts
// data:
{
  ledgers: Array<{ id: number; Ledger_Name: string; Ledger_Type: string; ledger_code: string | null }>;    // is_active only, matches Ledger_Name or ledger_code, take 10
  items: Array<{ id: number; Item_Name: string; Item_Code: string | null }>;                                // is_active only, matches Item_Name or Item_Code, take 10
  contacts: Array<{ id: number; Name: string; Phone_Number: string | null; Email: string | null; contact_type: string | null }>;  // matches Name/Phone_Number/Email, take 10
  vouchers: Array<{ id: number; voucher_no: string; voucher_type: string; voucher_prefix: string; voucher_date: Date }>;         // matches voucher_no, take 10, ordered by voucher_date desc
}
```

---

## 12. Reports routing map — **three different mount prefixes, easy to get wrong**

There is no single `/reports/*` namespace. `src/app.ts` mounts three separate report-bearing
routers under overlapping-looking prefixes, and one of them declares its own paths starting
with `/reports/...` **while being mounted at `/transactions`**, which doubles the prefix. This
has already caused real 404s (e.g. calling `GET /reports/balance-sheet` instead of the correct
`GET /transactions/reports/balance-sheet`) — check this table before wiring any report call.

| `app.ts` mount | Router file | Internal route prefix | **Resulting full path** | Reports |
|---|---|---|---|---|
| `app.use('/transactions', phase4Routes)` | `phase4.routes.ts` | `/reports/...` | **`/transactions/reports/...`** | ledger-statement, trial-balance, profit-loss, balance-sheet, day-book |
| `app.use('/transactions/reports', reportsRoutes)` | `reports.routes.ts` | `/...` (no extra prefix) | **`/transactions/reports/...`** | sales-register, purchase-register, stock-summary, stock-valuation, vat-return (+ `/excel` variant of each) |
| `app.use('/reports', dashboardRoutes)` | `dashboard.routes.ts` | `/dashboard`, `/dashboard/trend`, `/alerts`, `/search` | **`/reports/...`** | see §11 above |
| `app.use('/reports', analyticsRoutes)` | `analytics.routes.ts` | `/...` (no extra prefix) | **`/reports/...`** | see §15 below |

Net effect: the two router groups mounted at `/transactions/reports` land on the *same* full
prefix despite being registered differently in `app.ts` (one via a doubled internal path, one
via the mount path) — that part is a coincidence, not a guarantee for any future report added
the same way as `phase4Routes`. **Always confirm a report's full path from this table (or by
grepping `addPath(` in `scripts/generate-openapi.ts`) rather than assuming `/reports/<name>`.**

---

## 13. Financial statement reports (`phase4.routes.ts` §"Journal Ledger reports", `phase4.service.ts`, `phase4.controller.ts`)

Mounted at `/transactions/reports/...` (see §12). All gated by `authorize('JournalLedger', 'read')`.
None of these validate `company_id`/`branch_id` scoping — they query `journal_ledger`/`ledger_master`
globally.

### 13.1 `GET /transactions/reports/ledger-statement`

Query (validated by `ledgerStatementQuerySchema`, all **required**): `ledger_id` (numeric
string), `start_date`, `end_date` (`YYYY-MM-DD`).

```ts
// data:
{
  ledgerId: number;
  ledgerName: string;
  ledgerType: string;
  nature: string;            // 'Assets'|'Liabilities'|'Capital'|'Income'|'Expense' (from account group walk)
  openingBalance: number;    // master Opening_Balance adjusted for all pre-start_date entries
  entries: Array<{
    id: number; postingDate: string; voucherType: string; voucherNo: string;
    voucherPrefix: string; narration: string | null; debit: number; credit: number;
    runningBalance: number;
  }>;
  closingBalance: number;
}
```
404 `NotFoundError` if `ledger_id` doesn't exist.

### 13.2 `GET /transactions/reports/trial-balance`

Query (validated by `trialBalanceQuerySchema`): `as_of_date` (`YYYY-MM-DD`, optional — defaults
to today).

```ts
// data:
{
  asOfDate: string;   // YYYY-MM-DD
  entries: Array<{ ledgerId: number; ledgerName: string; ledgerType: string; nature: string; debit: number; credit: number }>;  // zero-balance ledgers omitted
  totalDebit: number;
  totalCredit: number;
  isBalanced: boolean;
}
```
Iterates **every active ledger** and computes balance-to-date per ledger — O(n) queries, no
pagination; expect this to be slow on large ledger masters.

### 13.3 `GET /transactions/reports/profit-loss`

Query (validated by `financialReportQuerySchema`, both **required**): `start_date`, `end_date`
(`YYYY-MM-DD`).

```ts
// data:
{
  period: { start: string; end: string };
  revenues: Array<{ ledgerId: number; name: string; amount: number }>;   // nature === 'Income', net credit-debit, only if > 0
  expenses: Array<{ ledgerId: number; name: string; amount: number }>;   // nature === 'Expense', net debit-credit, only if > 0
  totalRevenue: number;
  totalExpense: number;
  netProfit: number;
}
```

### 13.4 `GET /transactions/reports/balance-sheet`

Query: `end_date` (`YYYY-MM-DD`) — **read directly off `req.query`, no Zod schema/`validate()`
applied to this route**, unlike its siblings above. Passing nothing yields `new Date('')` →
`Invalid Date`; send a valid `end_date` explicitly.

```ts
// data:
{
  asOfDate: string;    // echoes the end_date query param verbatim
  assets: Array<{ ledgerId: number; name: string; amount: number }>;
  liabilities: Array<{ ledgerId: number; name: string; amount: number }>;
  capital: Array<{ ledgerId: number; name: string; amount: number }>;
  retainedEarnings: number;               // net profit (all-time revenue - expense, up to end_date) folded into capital
  totalAssets: number;
  totalLiabilitiesAndCapital: number;     // liabilities + capital (capital already includes retainedEarnings)
  isBalanced: boolean;                    // totalAssets === totalLiabilitiesAndCapital
}
```

### 13.5 `GET /transactions/reports/day-book`

Query: `date` (`YYYY-MM-DD`) — also **no validation schema**; all `journal_ledger` entries for
that single calendar day, no `company_id`/`branch_id` filter, no pagination.

```ts
// data: Array<{
  id: number; ledgerName: string; voucherType: string; voucherNo: string;
  debit: number; credit: number; narration: string | null;
}>
```

---

## 14. Operational reports (`reports.routes.ts`, `reports.service.ts`, `reportsExport.controller.ts`)

Mounted at `/transactions/reports/...` (see §12).

### 14.1 `GET /transactions/reports/sales-register` — `authorize('Transactions', 'read')`

Query: `start_date`, `end_date` (either/both, overridden by `financial_year` if `start_date`/
`end_date` absent — `financial_year` format `YYYY-YY` e.g. `2024-25`, parsed as Apr 1–Mar 31),
`prefix`, `customer_ledger_id`, `page` (default 1), `limit` (default 50, **no upper clamp**).

```ts
// data:
{
  items: Array<{ /* voucher_headers row */ id; voucher_type: 'SalesInvoice'; voucher_prefix; voucher_no; voucher_date; sales_invoice_main: {...} | null }>;
  meta: { total: number; page: number; limit: number; totalPages: number };
}
```

### 14.2 `GET /transactions/reports/purchase-register` — `authorize('Transactions', 'read')`

Same query shape as 14.1 with `vendor_ledger_id` instead of `customer_ledger_id`; `data.items[]`
carries `voucher_type: 'PurchaseInvoice'` + `purchase_invoice_main` instead.

### 14.3 `GET /transactions/reports/stock-summary` — `authorize('Inventory', 'read')`

Query: `as_of_date`, `godown_id`, `category_id` (all optional).

```ts
// data: Array<{
  item_id: number; item_name: string | undefined; godown_id: number;
  quantity_in: number; quantity_out: number; closing_qty: number;
}>
```
Not paginated, not wrapped in `{ items, meta }` — a bare array, unlike the register reports.

### 14.4 `GET /transactions/reports/stock-valuation` — `authorize('Inventory', 'read')`

Query: `as_of_date`, `godown_id` (optional).

```ts
// data: Array<{
  item_id: number; item_name: string | undefined; godown_id: number;
  closing_qty: number; avg_cost: number; total_value: number;
}>
```
Also a bare array. `avg_cost` divides `total_cost` by `quantity_in` only (not net of
`quantity_out`) — treat as approximate, not a strict weighted-average-of-remaining-stock figure.

### 14.5 `GET /transactions/reports/vat-return` — `authorize('Transactions', 'read')` (`VatReturnService.getReport`)

Query: `period` — either `YYYY-MM` (month) or `YYYY-QN` (quarter, e.g. `2025-Q2`); defaults to
the current month if omitted.

```ts
// data:
{
  period: string;
  start_date: Date; end_date: Date;
  sales_invoices: number; purchase_invoices: number;      // row counts
  total_sales_value: number; total_purchase_value: number; // sum of Total
  output_tax: number; input_tax: number;                   // sum of Vat_Amount
  net_vat_payable: number;                                 // output_tax - input_tax
}
```

### 14.6 Excel variants — `GET .../excel` for each of the above 5 reports

Same query params and RBAC as the JSON endpoint; **not** wrapped in `ApiResponse` — the
response body is a raw `.xlsx` binary (`ExportService.generateExcel`) with:
```
Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
Content-Disposition: attachment; filename="<report_name>.xlsx"
```
`sales-register/excel` and `purchase-register/excel` force `limit: 100000` server-side
(ignore any client-supplied `page`/`limit`) to export the full result set in one file.

---

## 15. Analytics endpoints (`src/modules/reports/analytics.routes.ts`, `analytics.controller.ts`, `analytics.service.ts`)

Mounted at `/reports/...` (see §12) — **not** under `/transactions`.

> **⚠️ These 19 endpoints currently return hard-coded static mock data.** `AnalyticsService`'s
> methods accept `start_date`/`end_date`/`as_of_date` but every one of them ignores those
> params and returns the same fixed sample rows every call — confirmed by reading
> `analytics.service.ts` in full. There is also a `analytics.schema.ts` with Zod query schemas
> (`analyticsDateRangeSchema`, `analyticsAsOfDateSchema`) that is **not wired into
> `analytics.routes.ts`** via any `validate()` call — query params aren't validated at all.
> Treat every response below as a fixture, not real data, until the backend replaces these
> stubs with real queries.

All gated per-route (`JournalLedger`, `Transactions`, `Inventory`, or `Employee` `read`, per
domain — see table). Query params, where accepted: `start_date`, `end_date` (`YYYY-MM-DD`) or
`as_of_date` (`YYYY-MM-DD`) — parsed with `new Date(...)`, no format validation.

| Path (under `/reports`) | RBAC module | Query params used | `data` shape (top-level key) |
|---|---|---|---|
| `GET /cash-flow-statement` | `JournalLedger` | start/end | `entries[]`: `activity_type, particulars, cash_inflow, cash_outflow, net_cash_flow` |
| `GET /budget-variance` | `JournalLedger` | start/end | `entries[]`: `account_group, budget_amount, actual_amount, variance` |
| `GET /bank-reconciliation` | `JournalLedger` | as_of | `entries[]`: `bank_name, book_balance, uncleared_deposits, uncleared_cheques, statement_balance` |
| `GET /fixed-assets-depreciation` | `JournalLedger` | as_of | `items[]`: `asset_name, asset_category, gross_block, accumulated_depreciation, net_book_value` |
| `GET /ap-forecast` | `Transactions` | as_of | `items[]`: `vendor_name, due_this_week, due_this_month, total_due` |
| `GET /sales-analytics` | `Transactions` | start/end | `items[]`: `category, unit_sales, total_revenue` |
| `GET /sales-margin` | `Transactions` | start/end | `items[]`: `item_name, revenue, cogs, gross_margin` |
| `GET /quotation-conversion-ratio` | `Transactions` | start/end | `items[]`: `salesrep_name, total_quotations, converted_orders, lost_quotations, conversion_rate` |
| `GET /salesperson-commission` | `Transactions` | start/end | `items[]`: `salesrep_name, territory, total_sales, commission_rate, earned_commission` |
| `GET /vendor-expenses` | `Transactions` | start/end | `items[]`: `category_name, vendor_name, total_amount` |
| `GET /price-variance` | `Transactions` | start/end | `items[]`: `item_name, vendor_name, standard_price, actual_price, variance_percent` |
| `GET /ppv-audit` | `Transactions` | start/end | `items[]`: `item_name, vendor_name, master_cost, po_unit_price, price_variance_amount` |
| `GET /vendor-leadtime-compliance` | `Transactions` | start/end | `items[]`: `vendor_name, total_pos, avg_promised_days, avg_actual_days, on_time_delivery_percent` |
| `GET /stock-movement` | `Inventory` | start/end | `items[]`: `item_name, turnover_ratio, movement_category, days_in_stock` |
| `GET /bom-production-costing` | `Inventory` | none | `items[]`: `finished_good_name, bom_code, raw_material_cost, overhead_cost, total_unit_cost` |
| `GET /bin-location-stock` | `Inventory` | none | `items[]`: `godown_name, bin_rack_code, item_name, on_hand_qty` |
| `GET /dead-stock-analysis` | `Inventory` | as_of | `items[]`: `item_name, last_movement_date, days_idle, closing_qty, total_stock_value` |
| `GET /collection-efficiency` | `Transactions` | start/end | `items[]`: `customer_name, dso_days, total_billed, total_collected` |
| `GET /statutory-payroll-compliance` | `Employee` | start/end | `items[]`: `employee_name, gross_pay, employee_pf_deduction, employer_pf_contribution, total_statutory_liability` |

All numeric-looking money fields in this section are returned as **strings** (e.g.
`"145000.00"`, `"+7.08%"`), not JSON numbers — consistent with these being formatted fixtures
rather than `Prisma.Decimal`/`Float` passthroughs like the rest of this contract.
