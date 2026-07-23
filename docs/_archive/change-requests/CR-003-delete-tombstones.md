# CR-003: No delete tombstones — hard-deletes disappear silently, soft-deletes have no delta feed
- **Status:** Open
- **Priority:** P0 (blocks frontend)
- **Module / Endpoint:** cross-cutting (all Master-CRUD entities)
- **Type:** Offline-sync gap
- **Found in step:** 0

## Problem
An offline client that cached a row locally has no server-driven way to learn the row was
deleted remotely.

## Evidence
- Soft-deleted rows (`is_active = false`) are filtered from default list queries
  (`BaseRepository.applySoftDelete` adds `{ is_active: true }` unless `includeInactive` is
  passed) — but `includeInactive` is a repository-level capability, not a documented public
  query param on any reviewed controller, and there is no "give me tombstones since T" mode.
- Hard-deleted entities (`Brand`, `Category`, `AccountGroup`, ledger extension tables — no
  `is_active` column at all) leave **no trace** when deleted; the row simply disappears.
- Legacy shadow tables `sales_invoice_main_deleted`, `sales_invoice_details_deleted`,
  `kot_details_deleted` exist in the schema (mirroring their live counterparts' columns) but
  **no current controller/service/route reads or writes them** — apparent leftover from a
  prior (Django-era) system, not exposed by this API.
- Voucher lifecycle has no `DELETE` endpoint at all (confirmed: no `router.delete` in
  `transactions.routes.ts`, `phase4.routes.ts`, `voucherLifecycle.routes.ts`,
  `voucherRead.routes.ts`); `cancel` flips `VoucherStatus` but keeps the row.

## Proposed change
For soft-deletable entities: expose `includeInactive`/`includeTombstones` as a documented query
param, paired with `updatedSince` (CR-001) so a delta pull surfaces `is_active=false` rows for
local removal. For hard-deletable entities (Brand/Category/AccountGroup/etc.): either switch
them to soft-delete, or write a tombstone row (id + deleted_at) to a queryable table on delete.

## Frontend impact / workaround
Until resolved: the client must periodically do a full-ID-set diff against a complete re-fetch
for hard-deletable entities to detect remote deletes locally. Soft-deletable entities use the
same full-diff fallback since `includeInactive` isn't wired to a public param.
