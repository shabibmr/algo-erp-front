# CR-001: No `updatedSince` delta filter on list endpoints
- **Status:** Open
- **Priority:** P0 (blocks frontend)
- **Module / Endpoint:** all list endpoints (Master-CRUD + voucher lists)
- **Type:** Offline-sync gap
- **Found in step:** 0

## Problem
The offline-first sync engine (Step 6) needs to pull only what changed since the last sync
cursor. No list endpoint anywhere in the backend supports this.

## Evidence
- `grep -rni "updatedSince|updated_since|changedSince|changed_since|delta" src` → zero matches.
- `BaseRepository.findMany(options)` (`src/core/repository/BaseRepository.ts:107-147`) accepts
  only `{ where, select, include, orderBy, page, limit, includeInactive, tx }` — no
  timestamp-cursor param.
- `ListFilters` in `src/modules/transactions/voucherRead.service.ts:6-15` filters on
  `start_date`/`end_date` (the voucher's *business* date), not `updated_at` — cannot detect
  edits/cancellations of older vouchers.

## Proposed change
Add an optional `updatedSince` (ISO timestamp) query param to every list endpoint (Master-CRUD
and voucher lists), applied as `WHERE updated_at > :updatedSince` (or the entity's equivalent
timestamp column), returned alongside a server `now()` cursor the client stores for the next
pull.

## Frontend impact / workaround
Until resolved, the sync engine (Step 6) does full poll-and-diff pulls per entity instead of
incremental pulls — functional but O(n) on every sync cycle. Code the `DeltaPuller` abstraction
against an `updatedSince` parameter so swapping in the real filter later is a one-line change
per datasource.
