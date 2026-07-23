# CR-006: Voucher line edits are delete+recreate with no line-level timestamp
- **Status:** Open
- **Priority:** P1
- **Module / Endpoint:** transactions / `VoucherEditService.edit` (all 18 voucher documents)
- **Type:** Offline-sync gap
- **Found in step:** 0

## Problem
Voucher detail/line tables have no `updated_at`, and editing a voucher's lines does not bump
the parent header's `updated_at` either — so there is no timestamp signal anywhere that a
voucher's lines changed.

## Evidence
- `VoucherEditService.edit` performs `deleteMany` + `createMany` on the detail table on every
  edit (new row `id`s each time, no line-level `updated_at` to diff against).
- The header's `updated_at`/`Last_Modified` is only touched by `BaseRepository`/direct Prisma
  calls elsewhere in the service — this particular edit path does not update it.

## Proposed change
Either (a) have `VoucherEditService.edit` explicitly bump the header's `updated_at` whenever
lines change, or (b) add `updated_at` to detail tables and stop the delete+recreate pattern in
favor of in-place upserts.

## Frontend impact / workaround
Until resolved: the sync engine cannot rely on a header `updated_at` bump to know lines
changed. Workaround: whenever a voucher of any status is pulled via delta sync (once CR-001
lands), always re-fetch and replace the full line set for that header rather than trying to
diff lines individually.
