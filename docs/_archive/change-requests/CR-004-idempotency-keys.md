# CR-004: No idempotency-key support on POST endpoints
- **Status:** Open
- **Priority:** P0 (blocks frontend)
- **Module / Endpoint:** all POST endpoints, especially voucher-posting (`sales-invoice`,
  `purchase-invoice`, `payment`, `receipt`, `contra`, `journal`, `credit-note`, `debit-note`,
  `quotation`, `sales-order`, `purchase-order`, `godown-transfer`, `delivery-note`,
  `receipt-note`, `material-in`, `requirement`, `stock-request`) and every Master-CRUD `POST`.
- **Type:** Offline-sync gap
- **Found in step:** 0

## Problem
The outbox processor (Step 6) must safely retry a queued "create" mutation after a flaky
connection without risking a duplicate side-effecting write (duplicate voucher with real
GL/stock/billwise postings, or a duplicate master row).

## Evidence
- `grep -rni "idempoten" src` → zero results anywhere — no header check, no request-body
  field, no idempotency-key table, no dedup logic.
- Voucher numbering (`TransactionHelperService.generateNextNumber`) guarantees gap-free,
  collision-free sequential numbers via a pessimistic row lock in the same DB transaction as
  the insert — this prevents *duplicate numbers*, but does not prevent a retried POST from
  creating a **second, distinct** voucher if the client's call timed out after the server had
  already committed.
- `X-Request-Id` is a pure echo/log-correlation header (see `api-contract.md` §5) — never
  looked up against prior requests, so it cannot double as an idempotency key today.

## Proposed change
Accept an `Idempotency-Key` header (client-generated UUID) on all POST endpoints. Server
stores `(idempotency_key, endpoint) → response` for a bounded window (e.g. 24h) and returns the
original response on a repeat with the same key instead of re-executing the write.

## Frontend impact / workaround
Until resolved: the outbox processor generates and stores its own `idempotencyKey` per
mutation (already part of the Step 5 outbox table design) but cannot pass it to the server for
enforcement. As a stopgap, before retrying an unconfirmed POST the client must first `GET` the
relevant list/detail endpoint to check whether a matching row already exists (e.g. by voucher
number range or a client-side correlation field) before resubmitting.
