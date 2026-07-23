# Backend Improvement Suggestions (living document)

Changes the **frontend** needs from the backend (`E:\work\algo-backend\models\backend`) to
build a clean, fast, correct **online** ERP client. This is a running log — new items are
appended as they are discovered during the build. Distinct from the archived
`docs/_archive/change-requests/`, which holds the **offline-sync** CRs (parked while we ship
online-only).

**Legend:** P0 = blocks the frontend · P1 = major friction / correctness risk · P2 = quality/perf.
**Status:** Open · Proposed · Accepted · Implemented · Rejected.

| ID | Title | Priority | Status |
|----|-------|----------|--------|
| BE-001 | Read current role's permission matrix | **P0** | Implemented |
| BE-002 | Full-text `search` on list endpoints | P1 | Implemented |
| BE-003 | Field filtering on list endpoints | P1 | Implemented |
| BE-004 | Sorting on list endpoints | P1 | Implemented |
| BE-005 | Idempotency keys on POST (double-submit safety) | P1 | Implemented |
| BE-006 | Active FinancialYear in session/`/auth/me` | P2 | Implemented |
| BE-007 | Standardize every list endpoint to the `Paginated<T>` envelope | P2 | Partially Implemented |
| BE-008 | Lightweight lookup/projection endpoints for FK pickers | P2 | Partially Implemented |
| BE-009 | Leave allocation create body missing `employee_id` | P1 | Implemented |
| BE-010 | No list endpoint for attendance summary / salary revisions (per-employee only) | P1 | Open |
| BE-011 | Two catalogued reports have no backend route at all | P1 | Open |
| BE-012 | Financial-statement report params are unvalidated and inconsistently named | P2 | Open |
| BE-013 | The 19 analytics report endpoints return hard-coded mock data | **P0** | Open |
| BE-014 | No customer balance / AR summary endpoint for the party picker | P2 | Open |
| BE-015 | No payment/receipt-against-invoice settlement allocation endpoint | P1 | Open |

---

## BE-001 — Read the current user's permission matrix  (P0)  — **Implemented**
**Resolution.** `GET /auth/permissions` (`src/core/auth/auth.routes.ts:18` →
`src/core/auth/auth.controller.ts:247-274`) returns the caller's role permission matrix in
exactly the shape proposed below, reading `req.user.roleId` and querying
`user_access_permissions`. `GET /auth/me` also now embeds the same `permissions` array
(`auth.controller.ts:229`). `PUT /organization/roles/:roleId/permissions` correctly calls
`clearPermissionCache(roleId)` (`organization.service.ts:361`) so the in-memory permission
cache in `authorize.ts` never serves stale data after an update.

**Original problem (for reference).** The UI must gate every menu/button/route by
`(module_name, action)`, but there was no endpoint that returned a role's permissions.
`authorize()` checks them server-side per-request (`src/core/middleware/authorize.ts`), and the
only exposure was `PUT /organization/roles/:roleId/permissions` — write-only, and itself gated by
`UserAccessPermission:update` (admin only). A normal user couldn't read their own permissions.

**Evidence.**
- `src/core/auth/auth.controller.ts` — `login` and `me` return user profile only, no permissions.
- `src/modules/organization/organization.routes.ts:187` — only a `PUT` for permissions exists.
- `src/core/middleware/authorize.ts:45` — reads `user_access_permissions` by `role_id + module_name`.

**Proposed change.** Add **`GET /auth/permissions`** (authenticated, no special RBAC) returning the
caller's role matrix — or embed it in `GET /auth/me`:
```jsonc
{ "success": true, "data": { "permissions": [
  { "module_name": "Brand", "Allow_Create": true, "Allow_Read": true,
    "Allow_Update": true, "Allow_Delete": false, "Allow_Share": false }
] } }
```
(Same row shape as `permissionsSchema` in `organization.schema.ts:129`.)

**Frontend impact — consumed.** `FailOpenPermissionService` is gone, replaced by
`MatrixPermissionService` (`lib/core/auth/permission_service.dart`), which answers `can()` from
the role's loaded matrix and **fails closed** — an unknown module, or a matrix that never loaded,
denies, mirroring `authorize.ts:62` (a missing `user_access_permissions` row is all-false).
`AuthRepositoryImpl` loads it from `GET /auth/permissions` after login (whose own response
carries no matrix) and off the embedded `permissions` array on `/auth/me`, and clears it on
logout. A failed matrix fetch fails the login rather than landing the user in a silently empty
app.

---

## BE-002 — Full-text `search` on list endpoints  (P1)  — **Implemented**
## BE-003 — Field filtering on list endpoints  (P1)  — **Implemented**
## BE-004 — Sorting on list endpoints  (P1)  — **Implemented**
**Resolution (all three).** `BaseRepository.findMany` (`src/core/repository/BaseRepository.ts`)
already supported `search`/`filters`/`sortBy`/`sortOrder`, but most repository subclasses hadn't
configured `searchFields`/`filterFields`, so the controller-parsed params were silently no-ops.
Fixed by:
- Extracting the previously-duplicated query-parsing logic into a shared
  `getQueryOptions(req)` helper (`src/core/utils/listQuery.ts`), now used by the
  inventory, accounts, and organization controllers instead of each hand-rolling its own copy.
- Adding `searchFields`/`filterFields` to every `BaseRepository` subclass in the inventory,
  accounts, organization, and employee modules that was missing them, matching the pattern
  already used by `LedgerMasterRepository` (`accounts.repository.ts`).
- Bringing `InventoryController.listInventoryItems` (previously only parsed `page`/`limit`) in
  line with the rest of the list endpoints.

Accept `?search=<q>`, `?<field>=<value>` (whitelisted per entity via `filterFields`), and
`?sortBy=<field>&sortOrder=asc|desc` on any list endpoint built on `BaseRepository.findMany`.

**Original problems (for reference).**
- *BE-002 search.* No list endpoint accepted a search term; controllers parsed only `page`/`limit`
  (e.g. `InventoryController.listBrands`, `src/modules/inventory/inventory.controller.ts:106`).
  Server-side search was impossible, so `CrudBloc.search` and the async FK-lookup field couldn't
  narrow results — they'd have had to page the whole table to the client. Proposed: accept
  `?search=<q>` and match it against each entity's natural display field(s) (e.g. Brand →
  `Brand_Name`; Ledger → name/code).
- *BE-003 filtering.* No way to filter a list by a column (status, group, active flag, FK). The
  voucher list ("filter by date range / status / customer", plan Step 12) and most master lists
  needed it. Proposed: accept a documented filter convention — either explicit params
  (`?status=posted&customer_id=42`) or a generic `?filter[field]=value`, whitelisted per entity.
- *BE-004 sorting.* No `sort` param; order was whatever Prisma returned. Data tables offered
  column sort, which could only sort the visible page. Proposed: accept
  `?sortBy=<field>&sortDir=asc|desc` mapped to `BaseRepository`'s existing `orderBy`, whitelisted
  per entity.

**Not touched.** Voucher list endpoints (Sales Invoice, Purchase Invoice, etc.) already have
their own independent, more elaborate search/filter/sort implementation in
`src/modules/transactions/voucherRead.service.ts` (`ListFilters`, `headerWhere`, `getOrderBy`) —
supporting `search`, `status`, date ranges, and `financial_year` — and needed no change.

**Frontend impact — consumed.** `RemoteDataSourceBase._queryParameters` now sends the params the
server actually reads. **This surfaced a live bug:** the client was sending `sortDir`, but
`listQuery.ts:24` reads `sortOrder` — so column sort silently no-opped. Worse, `sortDir` is not
in `RESERVED_KEYS`, so it fell through into `filters`, and `BaseRepository.findMany:166` only
drops unknown filter keys when a repository declares a non-empty `filterFields` — on any
repository without that whitelist, the stray `sortDir` would reach Prisma's `where` clause and
throw. Fixed to `sortOrder`.

Worth noting as a standing hazard for the backend: **an unrecognised query param is not inert**
— absent a `filterFields` whitelist it becomes a `where` condition. A defensive whitelist (or a
default-deny on unknown keys) in `getQueryOptions` would turn a 500 into a no-op.

---

## BE-005 — Idempotency keys on POST (double-submit safety)  (P1)  — **Implemented**
**Resolution.** `src/core/middleware/idempotency.ts`, registered globally in `src/app.ts`, honors
an `Idempotency-Key` header on all POST requests: a repeated key within a 1-hour TTL replays the
original cached response instead of re-running the handler.

**Known limitations (not yet addressed).**
- In-memory only (a plain `Map`, no Redis) — does not dedupe across multiple server instances.
- Does not verify the request *body* matches the original for a reused key.
- Not scoped per-user — a key collision across two different users' requests would incorrectly
  return one user's cached response to the other.

If voucher creation is going to depend on this for financial correctness, these gaps should be
closed (see task list) before relying on it beyond simple double-submit protection.

**Original problem (for reference).** Even fully online, a POST can be sent twice: user
double-taps, or the client retries on a dropped connection (the app uses `dio_smart_retry`). For
voucher creation (which posts GL/stock) a duplicate is a real financial error, not a cosmetic one.
Proposed: accept an `Idempotency-Key` header on create endpoints; if a key was already processed,
return the original result instead of creating a second record. (This overlaps offline `CR-004`;
it matters online too.)

**Frontend impact — NOT yet consumed.** No `Idempotency-Key` header is sent anywhere in
`lib/core/network` yet, and POST/PUT auto-retry stays disabled. Wiring the header up is cheap,
but doing so before the "not scoped per-user" gap above is closed would be actively unsafe —
a key collision across two users returns one user's cached response to the other. Close that
first, then send the header and re-enable POST retries.

---

## BE-006 — Active FinancialYear in the session  (P2)  — **Implemented**
**Resolution.** `GET /auth/me` (`auth.controller.ts:200-228`) resolves and returns
`data.activeFinancialYear = { id, fyCode, displayName, startDate, endDate, status }` — preferring
the FY flagged `is_default: true`, falling back to the most recent by `start_date desc`. A
dedicated `GET /organization/fy/active` endpoint also exists
(`organization.routes.ts:42` → `OrganizationController.getActiveFinancialYear`).

**Original problem (for reference).** Vouchers and most reports are scoped to a Financial Year,
but the session (`login` / `/auth/me`) used to carry only company/branch, not the active FY.
Proposed: add the active FY to `/auth/me` (`data.financialYearId`) or expose
`GET /organization/financial-years/active`.

**Frontend impact — NOT yet consumed.** `AuthUserDto` does not yet parse `activeFinancialYear`,
and nothing needs it until vouchers land (nothing FY-scoped is built). Pick it up with the first
FY-scoped screen rather than carrying an unused field.

---

## BE-007 — Standardize list endpoints to `Paginated<T>`  (P2)  — **Partially Implemented**
**Resolution so far.**
- **Silent-truncation bug fixed.** Several "give me everything" reference-data endpoints called
  `BaseRepository.findMany()` with no explicit `limit`, silently defaulting to `limit: 20` and
  truncating without any client-visible signal: `listCurrencies`, `listRoles`, `listBranches`,
  `listCompanyProfiles`, `listVoucherSeries`, `listProjects` (all in
  `src/modules/organization/organization.service.ts`). Each now passes an explicit `limit: 1000`
  with a comment documenting the "reference data — full list" intent.
- **Tree endpoints documented, not restructured.** `listInventoryGroups`
  (`inventory.service.ts`), `listDepartments` (`employee.service.ts`), and `listAccountGroups`
  (`accounts.service.ts`) all return the *whole* self-referential tree (per the codebase's
  hierarchy pattern) via a hardcoded `findMany({ limit: 1000 })`, decorated with `full_path`/
  `depth`, and wrapped in an `{ items, meta }` shape that only superficially resembles
  `Paginated<T>` — `meta.total` is accurate but `meta.page`/`totalPages` don't mean "page N of
  a scrollable list," they mean "the whole tree, capped at 1000 nodes." We chose the doc's
  second option (document as a non-paginated tree variant) rather than restructuring the
  response shape, since a real client-facing change here would require frontend coordination.
  Each is now marked with an explicit comment; still open work if you want the client to treat
  it as a genuinely distinct decoder rather than `Paginated<T>`.

**Still open.** No shared response-building helper exists (every controller hand-builds its
`ApiResponse<T>` literal) — worth adding if reducing this boilerplate matters, but it's
orthogonal to the envelope-shape question above.

**Original problem (for reference).** Most list endpoints returned `{items, meta}`, but some
returned a bare array (e.g. `listInventoryGroups`, returning a tree), forcing the generic client
to special-case these. Proposed: either wrap all lists in `Paginated<T>`, or clearly mark
tree/lookup endpoints as a documented non-paginated variant so the client selects the right
decoder deliberately.

**Frontend impact.** Tree/lookup endpoints (`listInventoryGroups`, `listDepartments`,
`listAccountGroups`) can safely be treated as "fetch everything, ignore `meta`" rather than
real pagination. Reference-data lists (`listCurrencies`, `listRoles`, `listBranches`, etc.) no
longer truncate at 20 rows.

---

## BE-008 — Lightweight lookup/projection endpoints for FK pickers  (P2)  — **Implemented (2 entities)**
**Resolution.** Added slim `(id, label)` projection endpoints for the two heaviest FK-picker
targets, following the existing `GET /inventory/conversion/lookup` convention:
- `GET /inventory/item/lookup?search=` → `InventoryItemService.lookupItems`
  (`src/modules/inventory/inventory.service.ts`) — returns `{ id, label, code }[]`.
- `GET /accounts/ledgers/lookup?search=` → `AccountsService.lookupLedgers`
  (`src/modules/accounts/accounts.service.ts`) — returns `{ id, label, code, type }[]`.

Both use `BaseRepository.findMany`'s existing `select`/`search` passthrough — no repository
changes were needed, only a route + thin controller method + service method each, capped at 50
results per query.

**Still open.** Only these two entities were covered (the ones flagged as heaviest in the original
report). Other FK-picker targets (Brand, Category, Godown, Employee, etc.) still consume the full
list endpoint. Extending the same pattern to additional entities is mechanical — copy the
`lookupItems`/`lookupLedgers` shape per entity.

**Original problem (for reference).** FK-lookup fields need `(id, label)` pairs, but list
endpoints return full rows (InventoryItem is heavy, includes relations) — fetching 20 fat rows
to render a dropdown is wasteful. Proposed: either support a projection (`?fields=id,name`) or
add slim lookup endpoints (`GET /inventory/items/lookup?search=`). Pairs naturally with BE-002.

**Frontend impact — NOT yet consumed.** `FkLookupField` still pages the full list endpoint; no
frontend code calls `/inventory/item/lookup` or `/accounts/ledgers/lookup` yet. Switching it over
is a data-source change only, and only worth doing once a form actually renders one of those two
heavy FKs.

---

## BE-009 — Leave allocation create body missing `employee_id`  (P1)  — **Implemented**
**Resolution.** `leaveAllocationSchema` in `employee.schema.ts` now requires `employee_id`.
`LeaveService.allocateLeave` already used `data.employee_id`; Zod previously stripped it.

**Frontend impact.** `employee_leave_allocation` can POST
`{ employee_id, leave_policy_id, year, allocated_days, carried_forward }`.

---

## BE-010 — No list endpoint for attendance summary / salary revisions  (P1)  — **Open**
**Problem.** `ReportCatalog` ships an *Attendance summary* and a *Salary revision history*
report, but both data sets exist server-side only as **per-employee** routes:
- `GET /employee/employees/:id/attendance-summary` (`employee.routes.ts:197`)
- `GET /employee/employees/:id/salary-revisions` (`employee.routes.ts:198`)

A report is a cross-employee list. `ReportDefinition` addresses an endpoint plus **query**
params — it has no way to express a **path** param, and there is no route that returns these
rows for all employees. Both reports 404 today (they point at `/employees/attendance-summary`
and `/employees/salary-revisions`, which do not exist under any mount).

**Proposed change.** Add period-scoped list endpoints alongside the per-employee ones:
```
GET /employee/reports/attendance-summary?start_date&end_date[&department_id]
GET /employee/reports/salary-revisions?start_date&end_date[&department_id]
```
returning `Paginated<T>` (or a bare array, like `/employee/reports/overtime` already does),
one row per employee. This mirrors the overtime report, which is exactly this shape and works.

**Frontend impact.** Blocked. Until these exist the two reports cannot be fixed by editing the
catalog; the alternative is an employee-picker param on the report, which changes what the
report *is* (one employee, not a register). Left pointing at the dead paths deliberately, so
they fail loudly rather than silently rendering an empty table.

---

## BE-011 — Two catalogued reports have no backend route at all  (P1)  — **Open**
**Problem.** *Inactive customer analysis* and *Leave balance register* are stamped in
`ReportCatalog` but no route serves them — not under `/reports` (`analytics.routes.ts` has 19
routes; neither is among them), not under `/transactions/reports`, not anywhere. Both 404.

A third, *Cash flow* (`/reports/cash-flow`), is a **phantom duplicate**: the real route is
`/reports/cash-flow-statement`, which the catalog already carries as a separate entry. That one
is a frontend bug, not a backend gap — the catalog entry should simply be deleted.

**Proposed change.** Either implement the two reports, or confirm they were speculative so the
frontend can drop them from the catalog and the menu. No strong preference from this side — but
they should not stay as dead menu items.

**Frontend impact.** Two menu entries that 404 on click. Not fixable frontend-side without
deleting them.

---

## BE-012 — Financial-statement report params are unvalidated and inconsistently named  (P2)  — **Open**
**Problem.** The five journal-ledger reports (`phase4.routes.ts:123-150`) disagree with each
other, and two skip validation entirely:

| Report | Param | Validated? |
|---|---|---|
| `trial-balance` | `as_of_date` | Zod (`trialBalanceQuerySchema`) |
| `ledger-statement` | `ledger_id`, `start_date`, `end_date` | Zod |
| `profit-loss` | `start_date`, `end_date` | Zod |
| **`balance-sheet`** | **`end_date`** | **none** |
| **`day-book`** | `date` | **none** |

`balance-sheet` is an as-of-date report that takes `end_date` while its sibling as-of-date
report (`trial-balance`) takes `as_of_date`. And because it has no `validate()` middleware,
a missing param reaches `new Date(undefined)` → `Invalid Date` → the service does date math on
it and returns **500** (`phase4.controller.ts:292` → `phase4.service.ts:1651`). Confirmed live:
`GET /transactions/reports/balance-sheet` with no param returns 500, not 400.

**Proposed change.** Rename `balance-sheet`'s param to `as_of_date` to match `trial-balance`
(keep `end_date` as an accepted alias for one release), and put a Zod schema on both
`balance-sheet` and `day-book` so a bad or missing date is a **400 with a field path**, not a 500.

**Frontend impact — worked around.** The catalog now sends `end_date` and marks it required, so
the client can't trigger the 500. If the param is renamed, this is a one-line catalog change —
say so and it'll follow.

---

## BE-013 — The 19 analytics report endpoints return hard-coded mock data  (P0)  — **Open**
**Problem.** Every route in `src/modules/reports/analytics.routes.ts` (cash-flow-statement,
budget-variance, bank-reconciliation, fixed-assets-depreciation, ap-forecast, sales-analytics,
sales-margin, quotation-conversion-ratio, salesperson-commission, vendor-expenses,
price-variance, ppv-audit, vendor-leadtime-compliance, stock-movement, bom-production-costing,
bin-location-stock, dead-stock-analysis, collection-efficiency, statutory-payroll-compliance)
returns **fixed sample rows**. `AnalyticsService` accepts `start_date`/`end_date`/`as_of_date`
and ignores them — the same fixture comes back for every date range. `analytics.schema.ts`
defines Zod query schemas that are never wired into the routes, so the params aren't validated
either.

Money fields come back as **formatted strings** (`"145000.00"`, `"+7.08%"`), unlike the rest of
the API — another tell that these are fixtures, and a decoding hazard if they're ever made real
without changing the wire type.

**Why P0.** These 19 reports are shipped in the menu and render cleanly. A user cannot tell
they're looking at fake numbers — the report *looks* like it worked. That is worse than a 404:
it's a correctness trap in a financial product. This is the highest-priority item in this doc.

**Proposed change.** Either implement the queries, or gate the routes behind a flag / return
`501 Not Implemented` until they're real, so the client can show "not available" instead of
plausible fiction.

**Frontend impact.** 19 of the ~49 catalogued reports are affected. The frontend currently has
no way to distinguish them from real reports. If a `501` (or an explicit `data.isMock` flag)
were returned, the report viewer could render an honest "not yet available" state.

---

## BE-014 — No customer balance / AR summary endpoint for the party picker  (P2)  — **Open**
**Problem.** There is no endpoint returning a ledger's outstanding balance, available credit, or
last invoice/payment. Only the static `creditSettings.creditLimit` is reachable, via the ledger
record itself (`GET /accounts/ledgers/:id`).

**Why it matters.** The sales-invoice form has a customer strip that is the natural place to warn
"this party is over their credit limit" *before* the user keys twenty lines. Without a balance
source, the panel can only show the static limit, which on its own doesn't tell the operator
anything actionable.

**Proposed change.** `GET /accounts/ledgers/:id/balance` returning at least
`{ outstanding, availableCredit, lastInvoice: { voucherNo, date, amount }, lastPayment: {...} }`,
with `Decimal` money as strings per the rest of the API.

**Frontend impact.** `_CustomerMetricsBar` in
`lib/features/transactions_sales_invoice/presentation/sales_invoice_form_page.dart` previously
displayed **hardcoded demo figures** (outstanding `25450`, `INV-0478`, `AED 5,000.00`) behind an
italic "Demo" disclaimer. Those were removed — showing fabricated AR numbers on a financial
document is the same trap as BE-013. The panel now shows only the real credit limit and will
expand again when this endpoint exists.

---

## BE-015 — No payment/receipt-against-invoice settlement allocation endpoint  (P1)  — **Open**
**Problem.** Payment/Receipt voucher entry needs to let a user allocate the paid/received amount
against one or more specific outstanding invoices (billwise settlement), not just against a
ledger. No route exposes a "settle payment X against outstanding invoice Y" write operation.

> Migrated from the archived offline change-request CR-007. Despite living in the offline CR set,
> this is a genuinely-missing **online** endpoint that the billwise-settlement UI needs regardless
> of offline — so it is tracked here as a live gap. See `docs/_archive/change-requests/`.

**Evidence.**
- `VoucherLineAllocation` (`phase4.schema.ts:10-30`, exposed read-only via
  `GET /transactions/line-allocations/:detailLineId`) models `allocation_type` ∈
  `EXPENSE|DISCOUNT|TAX|CHARGE|REBATE` — charge/discount/tax allocation, not
  payment-against-invoice settlement.
- `billwise_records` exist in the schema and are referenced in `voucherPosting.service.ts` /
  `voucherLifecycle.service.ts`, confirming billwise tracking at the data layer, but no route
  writes a settlement.
- `GET /accounts/outstanding/:ledgerId` (`accounts.routes.ts:127-129`) reads outstanding
  balances, but nothing writes a settlement allocation from a Payment/Receipt voucher.

**Proposed change.** Add a settlement-allocation array to the Payment/Receipt create/edit payload
(e.g. `allocations: [{ against_voucher_header_id, amount }]`) that writes matching
`billwise_records` rows tying the payment to specific outstanding invoices, and expose it on read.

**Frontend impact.** Until resolved, the Payment/Receipt screens render the settlement-allocation
UI against a client-side abstraction (a no-op/local-only repository method) and post the voucher
as ledger-only (unallocated), flagged in the UI as "not settled against specific invoices."

---

## How to use this doc
- When the build hits a backend limitation, **append a `BE-NNN` entry** here and add a table row.
- Reference the exact `src/...:line` evidence so the backend team can act quickly.
- Offline-sync-specific CRs are archived under `docs/_archive/change-requests/` (offline is parked).
