# CR-002: Inconsistent/missing `updated_at` across masters, voucher lines, 1:1 extensions
- **Status:** Open
- **Priority:** P0 (blocks frontend)
- **Module / Endpoint:** cross-cutting (Prisma schema)
- **Type:** Offline-sync gap
- **Found in step:** 0

## Problem
A reliable sync cursor requires every syncable row to carry an update timestamp. Coverage is
inconsistent: present on most masters and voucher headers, but absent on `companyprofile`
entirely, on every voucher **detail/line** table, and on 1:1 ledger extension tables.

## Evidence
Direct schema check (`prisma/schema.prisma`):
- `voucher_headers`: has `updated_at`.
- Most masters (`brands`, `category`, `account_groups`, `branch`, `financialyear`,
  `currencymaster`, `voucherseries`, `user_credentials`, `user_roles`, `department`,
  `designation`, `sales_inventory_items`, `item_batches`, `sku_master`, `tax_categories`,
  `employee_details`, …): have `updated_at` or `Last_Modified`.
- `companyprofile`: **no** `created_at`/`updated_at` at all (see CR-008).
- `sales_invoice_details` and every other voucher detail/line table: **no** independent
  timestamp — only the parent row has one, and even that isn't touched by line edits (see
  CR-006).
- `ledger_bank_details`, `ledger_credit_settings`, `ledger_tax_settings` (1:1 extensions):
  **no** timestamp columns.
- `currencyrates`: only `created_at` (append-only by convention, not enforced in code).
- `billwise_records`, `cheque_details`: single `timestamp`, no created/updated distinction.

## Proposed change
Add `updated_at` (auto-updating on write) to every table intended to be independently
syncable: `companyprofile`, all voucher detail/line tables, and the 1:1 ledger extension
tables. Where a parent-child relationship makes a line's own timestamp redundant, at minimum
ensure editing a child always bumps the parent's `updated_at` (currently it does not — see
CR-006).

## Frontend impact / workaround
Until resolved: `companyprofile` and 1:1 ledger extensions must always be fully re-fetched
(single-row entities, low cost). Voucher line changes require re-fetching full header+lines
for the affected voucher on any header `updated_at` bump, rather than trusting individual line
timestamps.
