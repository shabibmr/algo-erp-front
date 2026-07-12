# Voucher type matrix (frontend)

Legend: `[x]` list+post (or create) path works · `[~]` partial · `[ ]` not started

| Type | Blueprint | Line shape | List | Post | Package |
|------|-----------|------------|------|------|---------|
| SalesInvoice | `salesInvoice` | itemQty | `[x]` | `[x]` full trading UI | `transactions_sales_invoice` |
| Quotation | `quotation` | itemQty | `[x]` | `[x]` | `transactions_item_qty` |
| SalesOrder | `salesOrder` | itemQty | `[x]` | `[x]` | `transactions_item_qty` |
| DeliveryNote | `deliveryNote` | itemQty | `[x]` | `[x]` (+ SO convert) | `transactions_item_qty` |
| PurchaseOrder | `purchaseOrder` | itemQty | `[x]` | `[x]` | `transactions_item_qty` |
| ReceiptNote | `receiptNote` | itemQty | `[x]` | `[x]` (+ PO convert) | `transactions_item_qty` |
| PurchaseInvoice | `purchaseInvoice` | itemQty | `[x]` | `[x]` | `transactions_item_qty` |
| CreditNote | `creditNote` | itemQty | `[x]` | `[x]` | `transactions_item_qty` |
| DebitNote | `debitNote` | itemQty | `[x]` | `[x]` | `transactions_item_qty` |
| Payment | `payment` | ledgerAmount | `[x]` | `[x]` | `transactions_ledger_amount` |
| Receipt | `receipt` | ledgerAmount | `[x]` | `[x]` | `transactions_ledger_amount` |
| Journal | `journal` | debitCredit | `[x]` | `[x]` | `transactions_debit_credit` |
| Contra | `contra` | contraAmount | `[x]` | `[x]` | `transactions_debit_credit` |
| GodownTransfer | `godownTransfer` | itemQty | `[x]` | `[x]` from/to godown | `transactions_stock` |
| MaterialIn | `materialIn` | itemQty | `[x]` | `[x]` cr/dr qty | `transactions_stock` |
| Requirement | `requirement` | itemQty | `[x]` | `[x]` no godown | `transactions_stock` |
| StockRequest | `stockRequest` | itemQty | `[x]` | `[x]` request qty | `transactions_stock` |

See `voucher-blueprint-recipe.md` for how to register the next type.
