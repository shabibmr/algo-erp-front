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

## Organization module (found while registering Wave A5's Organization batch)

| Entity | Backend path | Reason deferred |
|---|---|---|
| FinancialYear | `/organization/financial-years` | Backend has no `DELETE` route (list/active/create/update only) — same "assumes full CRUD" gap already logged for Inventory above; second occurrence, delete-route flavor rather than PUT. |
| CurrencyRate | `/organization/currency-rates` | Backend has only `GET`/`POST` (no `PUT`/`DELETE`) — third occurrence of the partial-CRUD gap. |
| ConfigSetting | `/organization/config-settings` | Keyed by a string `gm_key`, not an int `id`; no create route — doesn't fit the `Repository<E, ID>` generic's implicit int-id shape without a design decision. |
| VoucherSeries | `/organization/voucher-series` | 3 FKs (`company_id`/`branch_id`/`financial_year_id`) into 3 different entities, two of which (CompanyProfile, FinancialYear) aren't registered — blocked on those, not new work of its own. |
| UserCredentials | `/organization/users` | Carries a `password` field — needs deliberate handling (never round-tripped back from the server, distinct widget), not a generic text field; also multi-FK (`contact_id`/`role_id`/`branch_id`). |
| ProjectMaster | `/organization/projects` | Self-referential `parent_project_master_id` — same `FieldType.selfFk` gap as InventoryGroup above. |
| CompanyProfile | `/organization/company-profile` | `Logo` is a `Bytes` field (binary) — same gap as ItemImage above; also no `DELETE` route (single-tenant profile). |

The FinancialYear/CurrencyRate findings **confirm** the partial-CRUD gap first seen in Inventory is
real and recurring (now 3 occurrences across 2 modules) — still not fixed this round, per the
"watch for a second occurrence" note above, now satisfied twice over.

Branch and Currency were initially blocked by a 4th occurrence of the same family (missing
`GET /:id`, not missing `PUT`/`DELETE`) — but unlike the entries above, that gap was small enough
to fix directly rather than defer: the 2 missing routes were added to
`organization.routes.ts`/`organization.controller.ts`/`organization.service.ts` this round, so
Branch and Currency are built as full masters, not listed here.

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
