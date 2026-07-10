# algoERP Backend — Offline-Sync Readiness Audit

> Scope: does the existing backend (`E:\work\algo-backend\models\backend`, read-only,
> COMPLETE) give a Flutter offline-first client the primitives it needs — delta sync,
> reliable timestamps, tombstones for deletes, safe retries, and bulk initial hydration?
> Method: grepped the full `src/` tree for the relevant patterns (`updatedSince`,
> `changedSince`, `delta`, `idempoten*`) — **zero matches for any of them** — then read the
> actual list-query builders (`BaseRepository.findMany`, `voucherRead.service.ts`
> `ListFilters`), the actual Prisma models for `updated_at`-family columns, and the actual
> delete code paths (`BaseRepository.delete`, `BrandService.deleteBrand`,
> `VoucherCancelService.cancel`). Findings below are evidence-first; do **not** turn these
> into fixes here — they feed a separate Change Requests file.

---

## (a) Delta / changed-since query param on list endpoints

**Missing.** Confirmed by:
- `grep -rni "updatedSince|updated_since|changedSince|changed_since|delta" src` → **no
  results anywhere in the codebase**.
- `BaseRepository.findMany(options)` (`src/core/repository/BaseRepository.ts:107-147`)
  accepts only `{ where, select, include, orderBy, page, limit, includeInactive, tx }` — no
  timestamp-cursor parameter exists in the generic repository that every Master-CRUD module
  is built on.
- `ListFilters` in `src/modules/transactions/voucherRead.service.ts:6-15` (the interface
  behind every voucher list endpoint) is:
  ```ts
  export interface ListFilters {
    start_date?: string; end_date?: string; prefix?: string; financial_year?: string;
    ledger_id?: number; status?: string; page?: number; limit?: number;
  }
  ```
  `start_date`/`end_date` filter on the **voucher's business date** (`voucher_date` /
  `Date_Created`), not on `updated_at` — they cannot be used to page through "what changed
  since I last synced," only "vouchers dated within a range," which misses edits/
  cancellations to older vouchers.
- Every Master-CRUD list controller reviewed (Brand, Category, Ledger, Item, Employee, …)
  passes only `{ page, limit }` from `req.query` through to the repository — no entity
  exposes a since-timestamp filter.

**Client impact:** a full poll-and-diff of every list endpoint is the only way to detect
remote changes; there is no server-side "give me what changed since T" primitive to build
incremental sync on.

---

## (b) `updated_at`/`updatedAt` timestamp presence on list/get responses

**Partially present — inconsistent across the surface.** Evidence, spot-checked directly
against `prisma/schema.prisma`:

| Table | Has an update-timestamp column? | Column name |
|---|---|---|
| `voucher_headers` | Yes | `updated_at` |
| `brands`, `category`, `account_groups`, `branch`, `financialyear`, `currencymaster`,
  `voucherseries`, `user_credentials`, `user_roles`, `department`, `designation`,
  `sales_inventory_items`, `item_batches`, `sku_master`, `godown` (has `Last_Modified` only,
  no `updated_at`), `tax_categories`, `employee_details`, most Employee/HR tables | Yes (mostly) | `updated_at` (or `Last_Modified`) |
| `companyprofile` | **No** | — no `created_at`/`updated_at` at all (verified in schema) |
| `sales_invoice_details` (and every other voucher **detail/line** table:
  `purchase_invoice_details`, `payment_voucher_details`, etc.) | **No** | line rows carry
  no independent timestamp — only the parent header/main row does |
| `ledger_bank_details`, `ledger_credit_settings`, `ledger_tax_settings` | **No** | 1:1
  extension tables have no timestamp columns |
| `currencyrates` | Only `created_at`, no `updated_at` (rates are append-only by convention, but nothing in code prevents an update) |
| `billwise_records`, `cheque_details` | Only a single `timestamp`, no distinct created/updated | — |
| `ledger_master` | `Date_Created` + `Last_Modified` (both nullable) | — |

**Client impact:** even where an `updated_at`-family column exists, it is not exposed as a
sync cursor (see (a)) — its presence alone doesn't help unless the client is willing to
fetch entire collections and diff by timestamp client-side, and even then **detail/line
rows and 1:1 extension rows won't tell you a row changed** if only they (not the parent)
were edited, because voucher-line edits go through `VoucherEditService.edit` which does
`deleteMany` + `createMany` on the detail table (new `id`s each time, no line-level
`updated_at` to check) — the *header's* `updated_at`/`Last_Modified` doesn't get touched by
this either (only the main table's own row is updated by `BaseRepository`/direct Prisma
calls in that service). This needs a resync of full details for the affected voucher on
every edit, not a per-line delta.

---

## (c) Soft-delete tombstone discoverability in delta responses

**Missing / inconsistent — and where it exists, it's an invisible sibling table, not a
tombstone in the list response.**

- Confirmed pattern: soft-deleted rows (`is_active = false`) are **filtered out** of default
  list queries (`BaseRepository.applySoftDelete` adds `{ is_active: true }` to `where`
  unless `includeInactive` is passed). There is no generic "include tombstones since T" mode
  wired to any route — `includeInactive` is a repository-level capability, not a documented
  public query param on any controller reviewed.
- Where entities are **hard-deleted** (Brand, Category, AccountGroup, ledger extension
  tables — no `is_active` column at all), the row simply disappears from the table; there is
  **no tombstone whatsoever**, soft or hard. A client that cached a Brand locally has no way
  to learn it was deleted except by periodically re-fetching the full list and diffing IDs
  itself.
- Interesting exception found in the schema (not wired to any API route):
  `sales_invoice_main_deleted`, `sales_invoice_details_deleted`, `kot_details_deleted` are
  **separate shadow tables** that mirror the structure of their live counterparts (confirmed
  by direct comparison — `sales_invoice_main_deleted` has the same columns as
  `sales_invoice_main` minus the FK relation). This strongly suggests deleted sales invoices
  are archived by moving the row to a `_deleted` table (a real hard-delete-with-archive
  pattern), but **no controller, service, or route in the current codebase reads from or
  writes to these `_deleted` tables** — they appear to be a legacy mechanism from the
  Django-era system this schema was inherited from, not something the current Express/Prisma
  API exposes. A sync client cannot discover a deleted SalesInvoice through this API at all
  today (cancel is the closest analog, but cancel keeps the row and just flips
  `VoucherStatus`, it does not delete it — voucher lifecycle has no `DELETE` endpoint,
  confirmed: no `router.delete` exists in `transactions.routes.ts`, `phase4.routes.ts`,
  `voucherLifecycle.routes.ts`, or `voucherRead.routes.ts`).

**Client impact:** for hard-deleted masters (Brand/Category/AccountGroup/etc.), the only
reliable way to detect a remote delete is a full-ID-set diff against a complete re-fetch;
there's no incremental tombstone feed to consume.

---

## (d) Idempotency key support on create (POST) endpoints

**Missing entirely.** Confirmed by:
- `grep -rni "idempoten" src` → **zero results** anywhere in the codebase — no header
  check, no request-body field, no idempotency-key table, no dedup logic.
- Voucher numbering (`TransactionHelperService.generateNextNumber`, used inside
  `voucherPosting.service.ts`) does guarantee **gap-free, collision-free sequential numbers**
  via a pessimistic row lock inside the same DB transaction as the insert (this *prevents
  duplicate voucher numbers*, but it does **not** prevent a retried POST from creating a
  **second, distinct** voucher with the next number if the client's network call
  timed out after the server had actually committed — the server has no way to recognize
  "this is the same logical request I already processed").
- `X-Request-Id` (see `api-contract.md` §5) is purely an echo/log-correlation header — the
  server never looks it up against prior requests before processing, so it cannot double as
  an idempotency key today even though the client might assume it could.
- Same finding applies uniformly across every POST endpoint reviewed: `sales-invoice`,
  `purchase-invoice`, `payment`, `receipt`, `contra`, `journal`, `credit-note`, `debit-note`,
  `quotation`, `sales-order`, `purchase-order`, `godown-transfer`, `delivery-note`,
  `receipt-note`, `material-in`, `requirement`, `stock-request`, and every Master-CRUD
  `POST` (Brand, Ledger, Employee, …).

**Client impact:** an offline-first client that queues a "post sales invoice" mutation and
retries it after a flaky connection (timeout, app killed mid-request, etc.) risks creating a
duplicate voucher with real GL/stock/billwise side effects. The client must implement its
own request-dedup discipline (e.g. never retry a POST whose outcome is unconfirmed without
first checking `GET .../sales-invoices?...` for a matching voucher) since the server
provides no safety net.

---

## (e) Bulk/batch hydration endpoint for initial sync

**Missing — no purpose-built bulk-export endpoint; the generic list endpoints are the only
option, and they are pagination-capped.**

- Every list endpoint uses the same `page`/`limit` mechanism; `voucherRead.service.ts`'s
  `parsePage()` **hard-caps `limit` at 200** (`Math.min(200, ...)`). Master-CRUD lists via
  `BaseRepository.findMany` default to `limit = 20` if unspecified, with **no observed
  upper-bound clamp in `BaseRepository` itself** (so a client could in principle request a
  very large `limit`, but there is no dedicated "give me everything" mode, no streaming
  response, no cursor-based pagination — just offset/limit, which gets slow at scale via
  `skip`).
- No `/export`, `/bulk`, `/sync`, `/hydrate`, or similar route exists in any `*.routes.ts`
  file across all 5 modules — confirmed by reading every route file in full (organization,
  accounts, inventory, employee, transactions × 6 route files).
- The closest thing to a bulk read is `GET /reports/search` (global search across ledgers/
  items/contacts/vouchers) but it's capped at 10 results per category and requires a
  query string ≥2 characters — not usable for hydration.
- The Dashboard (`GET /reports/dashboard`) and Alerts (`GET /reports/alerts`) endpoints
  return aggregated/derived data, not raw entity collections, so they don't help either.

**Client impact:** initial offline hydration of a large entity set (e.g. all
`sales_inventory_items`, all `ledger_master`) must be done by looping the standard
paginated list endpoint to exhaustion (`while page <= totalPages`) — functional, but far
less efficient than a purpose-built bulk export, and with no `updatedSince` filter (see (a))
there is also no way to make *repeat* hydrations incremental — every "resync everything"
is a full O(n) re-download.

---

## Summary table

| Capability | Status | Evidence |
|---|---|---|
| (a) Delta/`updatedSince` filter on lists | **Missing** | No matches for delta/updatedSince patterns anywhere in `src`; `ListFilters` and `BaseRepository.findMany` have no such param |
| (b) `updated_at`-style timestamp on read models | **Inconsistent** | Present on most masters and voucher headers; absent on `companyprofile`, all voucher detail/line tables, 1:1 ledger extension tables |
| (c) Tombstone for deletes in delta responses | **Missing** | Soft-deletes just filter out (`is_active=false`, no delta feed); hard-deletes (Brand/Category/AccountGroup/etc.) leave nothing; legacy `*_deleted` shadow tables exist in schema but are unused by any current route |
| (d) Idempotency key on POST | **Missing** | No idempotency logic anywhere in `src`; `X-Request-Id` is log-only, not dedup |
| (e) Bulk/batch hydration endpoint | **Missing** | Only generic paginated lists exist (capped at 200 for vouchers); no export/bulk/sync route in any module |

These five gaps are the basis for the offline-sync Change Requests to be filed separately.
