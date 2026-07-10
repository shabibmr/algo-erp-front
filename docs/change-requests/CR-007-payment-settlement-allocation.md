# CR-007: No payment/receipt-against-outstanding-invoice settlement allocation endpoint
- **Status:** Open
- **Priority:** P1
- **Module / Endpoint:** transactions / Payment, Receipt
- **Type:** Missing endpoint
- **Found in step:** 0

## Problem
Payment/Receipt voucher entry needs to let a user allocate the paid/received amount against
one or more specific outstanding invoices (billwise settlement), not just against a ledger.

## Evidence
- `VoucherLineAllocation` (`phase4.schema.ts:10-30`, exposed read-only via
  `GET /transactions/line-allocations/:detailLineId`) models `allocation_type` ∈
  `EXPENSE|DISCOUNT|TAX|CHARGE|REBATE` on a line — this is charge/discount/tax allocation, not
  payment-against-invoice settlement.
- `billwise_records` exist in the schema and are referenced in `voucherPosting.service.ts` /
  `voucherLifecycle.service.ts`, confirming billwise tracking exists at the data layer, but no
  route was found exposing a "settle payment X against outstanding invoice Y" write operation.
- `GET /accounts/outstanding/:ledgerId` (`accounts.routes.ts:127-129`) exists for reading
  outstanding balances, but nothing writes a settlement allocation from a Payment/Receipt
  voucher to specific outstanding bills.

## Proposed change
Add a settlement-allocation array to the Payment/Receipt create/edit payload (e.g.
`allocations: [{ against_voucher_header_id, amount }]`) that writes matching `billwise_records`
rows tying the payment to specific outstanding invoices, and expose it back on read.

## Frontend impact / workaround
Until resolved: the Payment/Receipt gold-template screens (Step 13, Financial family) render
the settlement-allocation UI against a client-side abstraction (a repository method that is a
no-op / local-only until the endpoint exists), and post the voucher as ledger-only (unallocated)
in the meantime — flagged clearly in the UI as "not settled against specific invoices."
