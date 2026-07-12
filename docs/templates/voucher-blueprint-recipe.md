# Voucher blueprint recipe

> Mined while shipping **Sales Invoice gold** (Sprint C). Prefer this over
> inventing a new document surface per voucher type.

## Pieces

| Piece | Path | Role |
|-------|------|------|
| **Line Engine** | `lib/core/domain/line_engine/` | Pure Dart qty×price, % discount, tax-on-net, document totals — `Decimal` only |
| **VoucherBlueprint** | `lib/core/vouchers/voucher_blueprint.dart` | Declares party, line shape, paths, RBAC, lifecycle flags |
| **DocumentSurface** | `lib/core/surfaces/document_surface.dart` | Header slot + `LineItemGrid` + live totals + Post button |
| **Feature package** | `lib/features/transactions_<type>/` | Domain draft/lines, DTO, repository, list + form pages |

## Checklist for a new voucher type

1. **Confirm API** in `docs/feature-inventory.md` + schema (`transactions.schema.ts` / `phase4.schema.ts`).
2. **Add** a `const VoucherBlueprint` on `VoucherBlueprints` (or a family file).
3. **Domain**: draft header + line class; map incomplete lines out of POST body.
4. **Line math**: for `itemQty` lines, feed `LineEngine` via `DocumentSurface.lineInputsOf`. Do **not** reimplement tax/discount in the UI.
5. **Repository**: list/get paths (usually plural) vs post path (often singular) — check routes.
6. **Form page**: header FKs + `DocumentSurface` columns; post online (server numbers vouchers).
7. **List page**: paginated list + New button; detail/lifecycle later if needed.
8. **Menu + router** + mapper/DTO tests.
9. **Update** `voucher-type-matrix.md` row to `[x]`.

## Sales Invoice reference

- Blueprint: `VoucherBlueprints.salesInvoice`
- Package: `lib/features/transactions_sales_invoice/`
- Post: `POST /transactions/sales-invoice`
- List: `GET /transactions/sales-invoices`
- Line shape: `item_id`, `quantity`, `price`, `discount_percent`, `tax_rate`
- Engine: discount = round(subtotal × disc%/100, 2); tax = round(net × tax%/100, 2); total = round(subtotal − discount + tax, 2)

## Out of scope (until product pressure)

- Generic draft-save for all types (SI post can land as Posted directly)
- Full lifecycle toolbar (approve/reject/cancel) — blueprint lists actions; wire when UI needs them
- Freezed blueprint registry / code gen
