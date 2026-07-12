# Backend Improvement Suggestions (living document)

Changes the **frontend** needs from the backend (`E:\work\algo-backend\models\backend`) to
build a clean, fast, correct **online** ERP client. This is a running log — new items are
appended as they are discovered during the build. Distinct from `docs/change-requests/`,
which currently holds the **offline-sync** CRs (deferred while we ship online-only).

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

## How to use this doc
- When the build hits a backend limitation, **append a `BE-NNN` entry** here and add a table row.
- Reference the exact `src/...:line` evidence so the backend team can act quickly.
- If an item is offline-specific, file it under `docs/change-requests/` instead and link it here.
