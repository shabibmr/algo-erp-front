# Voucher type matrix (frontend)

Legend: `[x]` list+post (or create) path works · `[~]` partial · `[ ]` not started

| Type | Blueprint | Line shape | List | Post | Package |
|------|-----------|------------|------|------|---------|
| SalesInvoice | `salesInvoice` | itemQty | `[x]` | `[x]` full trading UI (filters, draft edit, lifecycle, print, post&book) | `transactions_sales_invoice` |
| PurchaseInvoice | | itemQty | `[ ]` | `[ ]` | |
| Payment | | ledgerAmount | `[ ]` | `[ ]` | |
| Receipt | | ledgerAmount | `[ ]` | `[ ]` | |
| Contra | | contraAmount | `[ ]` | `[ ]` | |
| Journal | | debitCredit | `[ ]` | `[ ]` | |
| CreditNote | | itemQty | `[ ]` | `[ ]` | |
| DebitNote | | itemQty | `[ ]` | `[ ]` | |
| Quotation | | itemQty | `[ ]` | `[ ]` | |
| SalesOrder | | itemQty | `[ ]` | `[ ]` | |
| PurchaseOrder | | itemQty | `[ ]` | `[ ]` | |
| DeliveryNote | | itemQty | `[ ]` | `[ ]` | |
| ReceiptNote | | itemQty | `[ ]` | `[ ]` | |
| GodownTransfer | | itemQty | `[ ]` | `[ ]` | |
| MaterialIn | | itemQty | `[ ]` | `[ ]` | |
| Requirement | | itemQty | `[ ]` | `[ ]` | |
| StockRequest | | itemQty | `[ ]` | `[ ]` | |

See `voucher-blueprint-recipe.md` for how to register the next type.
