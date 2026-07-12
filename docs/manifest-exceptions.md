# Manifest exceptions

Entities that don't fit the flat 7-file recipe in `docs/manifest-spec.md` as-is. Per the Wave A5
rule, these are named here rather than forced through the recipe or used to justify forking
`MasterListSurface`/`MasterFormSurface` ad hoc.

## Inventory module (found while registering Wave A5's Inventory batch)

| Entity | Backend path | Reason deferred |
|---|---|---|
| ~~InventoryGroup~~ | `/inventory/group` | **Shipped** as `inventory_group` with `FieldType.selfFk` parent (self excluded in picker; cycle checks server-side). List shows `full_path`/`depth` from API. |
| InventoryItem (extras) | `/inventory/item` | Core + group FK shipped. Ancillary columns (HSN, KOT, times, weight, …) still off the form until needed. |
| Ingredient (BOM) | `/inventory/ingredient` | Two FKs into the *same* target entity (`sales_item_id` and `purchase_item_id`, both → InventoryItem) with different semantic roles. The recipe's only worked FK example (Designation→Department) is one FK per target; a second FK to the same entity needs two independent `FormFieldSpec.fk` fields with distinct `fkSearch`/`fkDisplayOf` closures pointed at the same repository — untested shape. |
| ~~SKUMaster~~ | `/inventory/sku` | **Shipped** as `inventory_sku` (hard delete; FK → Item; legacy `ITEM_ID` required). |
| ~~ItemBatch~~ | `/inventory/batch` | **Shipped** as `inventory_batch` (soft delete; required FK `item_id` → Item). |
| ItemImage | `/inventory/image` | No `PUT` route (same gap ItemProperty had, below) plus an `ImageBase64` field — `FieldType.binary` doesn't exist, and a create-only form that can't actually set the image isn't worth shipping. Revisit once `supportsUpdate` *and* a binary field type both exist. |
| RouteCustomerMapping | `/inventory/route/customer-mapping` | No `PUT` route; `customer_ledger_id` FK is cross-module (Accounts). |
| RouteMapping | `/inventory/route/mapping` | No `PUT` route; `salesperson_employee_id` FK is cross-module (Employee). |
| LedgerItemMapping | `/inventory/ledger-item-mapping` | No `PUT` route; PK is Prisma `@map("_id")`-mapped with no real int FK enforced in the schema. |
| PriceListEntry | `/inventory/pricelist-entry` | Backend has no list endpoint at all (only get-by-id/create/update/delete) — `MasterListSurface` needs a working `.list()`. |

## Organization module (found while registering Wave A5's Organization batch)

| Entity | Backend path | Reason deferred |
|---|---|---|
| CurrencyRate | `/organization/rates` | `GET /rates` is a currency+date lookup (`getExchangeRate(currencyId, date)`), not a paginated list — doesn't return the `{items, meta}` shape `MasterListSurface` needs regardless of CRUD completeness. No `PUT`/`DELETE` either. Doesn't fit the recipe even with `supportsUpdate`/`supportsDelete`. |
| ConfigSetting | `/organization/config-settings` | Keyed by a string `gm_key`, not an int `id`; no create route — doesn't fit the `Repository<E, ID>` generic's implicit int-id shape without a design decision. |
| ~~VoucherSeries~~ | `/organization/voucher-series` | **Shipped** as `organization_voucher_series`. `company_id` remains plain int (CompanyProfile deferred); branch + FY are optional FKs. `require_approval` toggles optional SI approval workflow. |
| UserCredentials | `/organization/users` | Carries a `password` field — needs deliberate handling (never round-tripped back from the server, distinct widget), not a generic text field; also multi-FK (`contact_id`/`role_id`/`branch_id`). |
| ProjectMaster | `/organization/projects` | Self-referential `parent_project_master_id` — same `FieldType.selfFk` gap as InventoryGroup above. |
| CompanyProfile | `/organization/company-profile` | `Logo` is a `Bytes` field (binary) — same gap as ItemImage above; also no `DELETE` route (single-tenant profile). |

Branch and Currency were initially blocked by a different gap in the same family (missing
`GET /:id`, not missing `PUT`/`DELETE`) — but unlike the entries above, that gap was small enough
to fix directly rather than defer: the 2 missing routes were added to
`organization.routes.ts`/`organization.controller.ts`/`organization.service.ts`, so Branch and
Currency are built as full masters, not listed here.

## Cross-cutting gap: resolved via `supportsUpdate`/`supportsDelete`

**Status: fixed in EMR** (see `EntityManifest.supportsUpdate` /
`EntityManifest.supportsDelete` and `docs/manifest-spec.md` checklist).

The old "assumes full CRUD" gap was hit 4 times across Inventory and Organization
(ItemProperty/ItemImage missing `PUT`; FinancialYear missing `DELETE`; CurrencyRate missing both) —
past the "watch for a second occurrence" threshold. Rather than defer a 5th entity, `EntityManifest`
gained `supportsUpdate`/`supportsDelete` flags (default `true`), and `MasterFormSurface` now renders
edit mode read-only (banner, fields disabled, no Save; `_submit` refuses update) when
`supportsUpdate` is `false`, and hides Delete (and no-ops `_delete`) when `supportsDelete` is
`false`, instead of assuming every manifest with `formFields` supports both.

**Unblocked and shipped** (no longer listed in the deferred tables above):
- **ItemProperty** (`/inventory/property`) — `supportsUpdate: false`. List/create/delete +
  read-only edit.
- **FinancialYear** (`/organization/fy`) — `supportsDelete: false` (also needed `GET /:id`,
  added like Branch/Currency). List/create/update, no delete. Full 7-file package + routes + menu.

The other two stay deferred for reasons the flag doesn't reach:
- **ItemImage** — the missing `PUT` is now fixable via `supportsUpdate: false`, but the
  `ImageBase64` field still has no `FieldType` to render it with; a form that can create
  records but never set their actual payload isn't worth shipping. Revisit when
  `FieldType.binary` exists.
- **CurrencyRate** — its `GET` isn't a paginated list endpoint at all (see the table above),
  so this was never actually a `supportsUpdate` problem.

One list-endpoint gap (PriceListEntry) was also seen once — not yet cross-cutting, but watch for
a second occurrence before deciding whether it needs its own manifest flag.
