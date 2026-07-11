# Manifest exceptions

Entities that don't fit the flat 7-file recipe in `docs/manifest-spec.md` as-is. Per the Wave A5
rule, these are named here rather than forced through the recipe or used to justify forking
`MasterListSurface`/`MasterFormSurface` ad hoc.

## Inventory module (found while registering Wave A5's Inventory batch)

| Entity | Backend path | Reason deferred |
|---|---|---|
| InventoryGroup | `/inventory/group` | Self-referencing `parent_group_id` — needs `FieldType.selfFk` + a tree-picker widget, neither of which exist yet. |
| InventoryItem | `/inventory/item` | ~50 fields; 4 FKs into `ledger_master`, which lives in the Accounts domain, not Inventory — needs a design decision on cross-module FK repositories before it fits the single-FK recipe (Designation→Department is same-module). |
| Ingredient (BOM) | `/inventory/ingredient` | Two FKs into the *same* target entity (`sales_item_id` and `purchase_item_id`, both → InventoryItem) with different semantic roles. The recipe's only worked FK example (Designation→Department) is one FK per target; a second FK to the same entity needs two independent `FormFieldSpec.fk` fields with distinct `fkSearch`/`fkDisplayOf` closures pointed at the same repository — untested shape. |
| SKUMaster | `/inventory/sku` | FK → InventoryItem, which isn't registered yet. Blocked on InventoryItem, not new work of its own. |
| ItemBatch | `/inventory/batch` | FK → InventoryItem, same blocker as SKUMaster. |
| ItemProperty | `/inventory/property` | Backend has no `PUT` route (create/list/delete only) — `MasterFormSurface`'s edit mode has nothing to call. |
| ItemImage | `/inventory/image` | No `PUT` route (same gap as ItemProperty) plus an `ImageBase64` field — `FieldType.binary` doesn't exist. |
| RouteCustomerMapping | `/inventory/route/customer-mapping` | No `PUT` route; `customer_ledger_id` FK is cross-module (Accounts). |
| RouteMapping | `/inventory/route/mapping` | No `PUT` route; `salesperson_employee_id` FK is cross-module (Employee). |
| LedgerItemMapping | `/inventory/ledger-item-mapping` | No `PUT` route; PK is Prisma `@map("_id")`-mapped with no real int FK enforced in the schema. |
| PriceListEntry | `/inventory/pricelist-entry` | Backend has no list endpoint at all (only get-by-id/create/update/delete) — `MasterListSurface` needs a working `.list()`. |

## Cross-cutting gap worth naming

Five of the eleven entities above are blocked purely because the backend has **no `PUT` route**.
`MasterFormSurface` currently assumes every manifest with `formFields` supports create *and*
update. This is a real, repeated gap (not a one-off) — worth deciding deliberately (e.g. a
`readOnlyEdit`/`createOnly` manifest flag that disables the Save button but still shows the
detail) before the next Wave A5 batch, since Accounts/Employee likely have their own
partial-CRUD entities too. Not fixed in this round to avoid smuggling a Surface change in via one
entity's workaround — flagged here so it doesn't get re-discovered from scratch next time.

One list-endpoint gap (PriceListEntry) was also seen once — not yet cross-cutting, but watch for
a second occurrence before deciding whether it needs its own manifest flag.
