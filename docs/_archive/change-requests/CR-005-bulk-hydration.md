# CR-005: No bulk/batch hydration endpoint for initial sync
- **Status:** Open
- **Priority:** P1
- **Module / Endpoint:** all modules (no `/export`, `/bulk`, `/sync`, `/hydrate` route exists)
- **Type:** Offline-sync gap
- **Found in step:** 0

## Problem
First-run offline hydration of large entity sets (e.g. all `sales_inventory_items`, all
`ledger_master`) has no purpose-built bulk-read path.

## Evidence
- Every list endpoint uses `page`/`limit`; `voucherRead.service.ts`'s `parsePage()` hard-caps
  `limit` at 200 (`Math.min(200, ...)`). Master-CRUD lists via `BaseRepository.findMany`
  default to `limit = 20` with no observed upper clamp, but there's no dedicated "give me
  everything" mode — offset/limit only, which gets slow via Prisma `skip` at scale.
- No `/export`, `/bulk`, `/sync`, `/hydrate` route in any of the 6 route files across all 5
  modules (confirmed by reading each in full).
- `GET /reports/search` is capped at 10 results/category and needs a ≥2-char query — not
  usable for hydration. Dashboard/Alerts return aggregates, not raw collections.

## Proposed change
Add a bulk hydration endpoint per major entity (or one generic `/sync/bootstrap?entities=...`)
that streams/paginates without the 200-row cap, ideally cursor-based rather than offset/limit,
for first-run device setup.

## Frontend impact / workaround
Until resolved: initial hydration loops the standard paginated list endpoint to exhaustion
(`while page <= totalPages`) per entity. Combined with CR-001 (no `updatedSince`), every
"resync everything" scenario is also a full O(n) re-download, not just first-run.
