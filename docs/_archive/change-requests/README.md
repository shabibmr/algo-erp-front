# Change Requests — Index

Tracks backend gaps/ambiguities discovered while building the algoERP Flutter frontend.
Use `_TEMPLATE.md` for new entries. File name convention: `CR-<NNN>-<slug>.md`.

| ID | Title | Priority | Type | Status |
|---|---|---|---|---|
| [CR-001](CR-001-delta-sync-filter.md) | No `updatedSince` delta filter on list endpoints | P0 | Offline-sync gap | Open |
| [CR-002](CR-002-inconsistent-timestamps.md) | Inconsistent/missing `updated_at` on masters, voucher lines, 1:1 extensions | P0 | Offline-sync gap | Open |
| [CR-003](CR-003-delete-tombstones.md) | No delete tombstones (hard-deletes disappear silently; soft-deletes not exposed as a delta feed) | P0 | Offline-sync gap | Open |
| [CR-004](CR-004-idempotency-keys.md) | No idempotency-key support on POST endpoints | P0 | Offline-sync gap | Open |
| [CR-005](CR-005-bulk-hydration.md) | No bulk/batch hydration endpoint for initial sync | P1 | Offline-sync gap | Open |
| [CR-006](CR-006-line-level-sync.md) | Voucher line edits are delete+recreate with no line-level timestamp | P1 | Offline-sync gap | Open |
| [CR-007](CR-007-payment-settlement-allocation.md) | No payment/receipt-against-outstanding-invoice settlement allocation endpoint | P1 | Missing endpoint | Open |
| [CR-008](CR-008-companyprofile-timestamps.md) | `companyprofile` has no `created_at`/`updated_at` at all | P2 | Offline-sync gap | Open |

## Already verified as NOT gaps (checked against actual backend source, contradicting the plan doc's assumptions)

The `PROMPT_EXECUTION_PLAN.md` "known gaps" list named several items that turned out to already be implemented in this backend. No CRs filed for these — confirmed present:

- **Quotation→SalesOrder / SalesOrder→PurchaseOrder conversion**: `source_voucher_id` field on the Sales/Purchase Order schemas (`phase4.schema.ts:134,154`) plus conversion logic in `phase4.service.ts` (lines ~786, ~969) — conversion is supported.
- **Stock-ledger read filters**: `GET /inventory/stock-ledger/:itemId`, `GET /inventory/stock-ledger/godown/:godownId`, `GET /inventory/stock-balance`, `GET /inventory/stock-balance/:itemId/by-godown` all exist (`inventory.routes.ts:424-436`).
- **Trial-balance / P&L / balance-sheet**: `GET /transactions/reports/trial-balance`, `/reports/profit-loss`, `/reports/balance-sheet` all exist and are wired (`phase4.routes.ts:129-147`).
- **Audit-log read endpoint**: `GET /organization/audit-logs` exists, gated by `authorize('AuditLog', 'read')` (`organization.routes.ts:174`).

Only the **payment/receipt settlement-allocation** gap (CR-007) held up under inspection — `VoucherLineAllocation` exists but models expense/discount/tax/charge/rebate allocation on a *line*, not payment-against-outstanding-invoice settlement.
