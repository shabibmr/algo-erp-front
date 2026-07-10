# Backend Improvement Suggestions (living document)

Changes the **frontend** needs from the backend (`E:\work\algo-backend\models\backend`) to
build a clean, fast, correct **online** ERP client. This is a running log — new items are
appended as they are discovered during the build. Distinct from `docs/change-requests/`,
which currently holds the **offline-sync** CRs (deferred while we ship online-only).

**Legend:** P0 = blocks the frontend · P1 = major friction / correctness risk · P2 = quality/perf.
**Status:** Open · Proposed · Accepted · Implemented · Rejected.

| ID | Title | Priority | Status |
|----|-------|----------|--------|
| BE-001 | Read current role's permission matrix | **P0** | Open |
| BE-002 | Full-text `search` on list endpoints | P1 | Open |
| BE-003 | Field filtering on list endpoints | P1 | Open |
| BE-004 | Sorting on list endpoints | P1 | Open |
| BE-005 | Idempotency keys on POST (double-submit safety) | P1 | Open |
| BE-006 | Active FinancialYear in session/`/auth/me` | P2 | Open |
| BE-007 | Standardize every list endpoint to the `Paginated<T>` envelope | P2 | Open |
| BE-008 | Lightweight lookup/projection endpoints for FK pickers | P2 | Open |

---

## BE-001 — Read the current user's permission matrix  (P0)
**Problem.** The UI must gate every menu/button/route by `(module_name, action)`, but there is
**no endpoint that returns a role's permissions**. `authorize()` checks them server-side
per-request (`src/core/middleware/authorize.ts`), and the only exposure is
`PUT /organization/roles/:roleId/permissions` — write-only, and itself gated by
`UserAccessPermission:update` (admin only). A normal user can't read their own permissions.

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

**Frontend impact / interim.** Until this lands, `PermissionService` will **fail-open** (show
everything) and rely on server `403`s — insecure UX (buttons that error on click). We keep
`PermissionService` behind its Wave-0 interface so the real matrix drops in with zero feature edits.

---

## BE-002 — Full-text `search` on list endpoints  (P1)
**Problem.** No list endpoint accepts a search term; controllers parse only `page`/`limit`
(e.g. `InventoryController.listBrands`, `src/modules/inventory/inventory.controller.ts:106`).
Server-side search is impossible, so `CrudBloc.search` and the **async FK-lookup field** can't
narrow results — they'd have to page the whole table to the client.

**Proposed change.** Accept `?search=<q>` and match it against each entity's natural display
field(s) (e.g. Brand → `Brand_Name`; Ledger → name/code). `BaseRepository.findMany` already
takes a `where`; only the controller→`where` translation is missing.

**Frontend impact / interim.** FK-lookup and list search filter **client-side within the current
page only** — acceptable for tiny tables, wrong for large ones. Encoded behind the
`RemoteDataSource` interface so enabling server search later is a one-line switch.

---

## BE-003 — Field filtering on list endpoints  (P1)
**Problem.** No way to filter a list by a column (status, group, active flag, FK). The voucher
list ("filter by date range / status / customer", plan Step 12) and most master lists need it.

**Proposed change.** Accept a documented filter convention — either explicit params
(`?status=posted&customer_id=42`) or a generic `?filter[field]=value`. Whitelist per entity.

**Frontend impact / interim.** Filters apply client-side on the loaded page only. Behind the
`PageQuery` value object, so a server implementation needs no bloc/UI change.

---

## BE-004 — Sorting on list endpoints  (P1)
**Problem.** No `sort` param; order is whatever Prisma returns. Data tables offer column sort,
which currently can only sort the visible page.

**Proposed change.** Accept `?sortBy=<field>&sortDir=asc|desc` mapped to `BaseRepository`'s
existing `orderBy`. Whitelist sortable fields per entity.

**Frontend impact / interim.** Column sort acts on the current page only.

---

## BE-005 — Idempotency keys on POST (double-submit safety)  (P1)
**Problem.** Even fully online, a POST can be sent twice: user double-taps, or the client retries
on a dropped connection (the app uses `dio_smart_retry`). For **voucher creation** (which posts
GL/stock) a duplicate is a real financial error, not a cosmetic one.

**Proposed change.** Accept an `Idempotency-Key` header on create endpoints; if a key was already
processed, return the original result instead of creating a second record. (This overlaps offline
`CR-004`; it matters **online too**.)

**Frontend impact / interim.** The frontend will (a) **not auto-retry POST/PUT** by default in the
retry interceptor, and (b) disable submit buttons while in-flight. A server key would let us safely
re-enable POST retries.

---

## BE-006 — Active FinancialYear in the session  (P2)
**Problem.** Vouchers and most reports are scoped to a Financial Year, but the session
(`login` / `/auth/me`) carries only company/branch, not the active FY.

**Proposed change.** Add the active FY to `/auth/me` (`data.financialYearId`) or expose
`GET /organization/financial-years/active`.

**Frontend impact / interim.** Frontend fetches the FY list and picks the current-dated one,
storing it in `SessionContext`. Works, but "current FY" is then a client guess.

---

## BE-007 — Standardize list endpoints to `Paginated<T>`  (P2)
**Problem.** Most list endpoints return `{items, meta}`, but some return a bare array
(e.g. `listInventoryGroups`, `src/modules/inventory/inventory.controller.ts:349`, returns a tree).
The generic client must special-case these.

**Proposed change.** Either wrap all lists in `Paginated<T>`, or clearly mark tree/lookup endpoints
as a documented non-paginated variant so the client selects the right decoder deliberately.

**Frontend impact / interim.** We tag such endpoints in `docs/feature-inventory.md` and use a
non-paginated datasource variant for them.

---

## BE-008 — Lightweight lookup/projection endpoints for FK pickers  (P2)
**Problem.** FK-lookup fields need `(id, label)` pairs, but list endpoints return full rows
(InventoryItem is heavy, includes relations). Fetching 20 fat rows to render a dropdown is wasteful.

**Proposed change.** Either support a projection (`?fields=id,name`) or add slim lookup endpoints
(`GET /inventory/items/lookup?search=`). Pairs naturally with BE-002.

**Frontend impact / interim.** FK-lookup consumes the full list endpoint and maps to `(id,label)`
locally — more bytes over the wire than necessary.

---

## How to use this doc
- When the build hits a backend limitation, **append a `BE-NNN` entry** here and add a table row.
- Reference the exact `src/...:line` evidence so the backend team can act quickly.
- If an item is offline-specific, file it under `docs/change-requests/` instead and link it here.
