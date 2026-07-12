# Voucher blueprint recipe

> Mined while shipping **Sales Invoice gold** (Sprint C) and the **item-qty
> trading family** (Sprint D). Prefer this over inventing a new document
> surface per voucher type.

## Pieces

| Piece | Path | Role |
|-------|------|------|
| **Line Engine** | `lib/core/domain/line_engine/` | Pure Dart qty×price, % discount, tax-on-net, document totals — `Decimal` only |
| **VoucherBlueprint** | `lib/core/vouchers/voucher_blueprint.dart` | Declares party, line shape, paths, RBAC, lifecycle flags |
| **ItemQty engine** | `lib/core/vouchers/item_qty/` | Shared models/DTO/repo + `ItemQtyKinds` for trading vouchers |
| **DocumentSurface** | `lib/core/surfaces/document_surface.dart` | Header slot + `LineItemGrid` + live totals + Post button |
| **Item-qty UI** | `lib/features/transactions_item_qty/` | One list/form/detail parameterized by kind |
| **SI gold package** | `lib/features/transactions_sales_invoice/` | Full lifecycle / print / draft edit reference |

## Checklist for a new voucher type

1. **Confirm API** in `docs/feature-inventory.md` + schema (`transactions.schema.ts` / `phase4.schema.ts`).
2. **Add** a `const VoucherBlueprint` on `VoucherBlueprints`.
3. **If `itemQty` trading voucher** (customer/supplier + lines): add an `ItemQtyVoucherKind` on `ItemQtyKinds` (main nest key, party field, godown/source flags). Reuse `transactions_item_qty` — no new package.
4. **If a different line shape** (Payment/Journal/…): new domain + repository; still use `DocumentSurface` + `LineEngine` where amounts apply.
5. **Line math**: for `itemQty` lines, feed `LineEngine` via `DocumentSurface.lineInputsOf`. Do **not** reimplement tax/discount in the UI.
6. **Repository**: list/get paths (usually plural) vs post path (often singular). Phase-4 posts often return `headerId`; PI returns `id` (`ItemQtyVoucherKind.postIdKey`).
7. **Menu + router** (list menu arm; `new` + `:id` via `_itemQtyRoutes` or SI-style routes) + DTO tests.
8. **Update** `voucher-type-matrix.md` row to `[x]`.

## Sales Invoice reference (gold / full lifecycle)

- Blueprint: `VoucherBlueprints.salesInvoice`
- Package: `lib/features/transactions_sales_invoice/`
- Post: `POST /transactions/sales-invoice`
- List: `GET /transactions/sales-invoices`
- Line shape: `item_id`, `quantity`, `price`, `discount_percent`, `tax_rate`
- Engine: discount = round(subtotal × disc%/100, 2); tax = round(net × tax%/100, 2); total = round(subtotal − discount + tax, 2)

## Sprint D families

### Item-qty (`itemQty`)

- Core: `lib/core/vouchers/item_qty/`
- UI: `lib/features/transactions_item_qty/`
- Kinds: Quotation, SalesOrder, DeliveryNote, PurchaseOrder, ReceiptNote,
  PurchaseInvoice, CreditNote, DebitNote
- DN converts from SalesOrder; RN from PurchaseOrder
- Credit/Debit notes use party field `ledger_id` (not customer/supplier)

### Ledger-amount (`ledgerAmount`)

- Core: `lib/core/vouchers/ledger_amount/`
- UI: `lib/features/transactions_ledger_amount/`
- Kinds: Payment, Receipt
- Header: cash/bank ledger; lines: counterparty ledger + amount
- Totals via LineEngine (qty=1 × amount). No billwise allocation UI yet.

### Debit-credit (`debitCredit` / `contraAmount`)

- Core: `lib/core/vouchers/debit_credit/`
- UI: `lib/features/transactions_debit_credit/`
- Journal: debit + credit columns; Contra: amount + DR/CR side
- Client balance bar (debits must equal credits); min 2 lines
- Custom form (not DocumentSurface) — LineEngine is qty×price, not GL double-entry

### Stock (`StockVoucherKind`)

- Core: `lib/core/vouchers/stock/`
- UI: `lib/features/transactions_stock/`
- GodownTransfer: from/to godown + item qty/price/adj
- MaterialIn: optional godown + crQty/drQty/Price
- Requirement: no godown + item qty/price
- StockRequest: from/to godown + inventory_item_id/request_qty
- List nest for GT uses backend typo `godown_tranfer_main`

## Out of scope (until product pressure)

- SI-parity draft-edit / approve / print for every type (cancel is wired)
- Payment/Receipt settlement allocation honesty (CR-007)
- Freezed blueprint registry / code gen
