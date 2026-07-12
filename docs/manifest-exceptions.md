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

## Employee module (Sprint F)

| Entity | Backend path | Reason deferred / partial |
|---|---|---|
| ~~EmployeeDetails~~ | `/employee/employees` | **Shipped** as `employee_employee` with tabbed Core/Bank/Salary (nested `bankDetails` / `salaryDetails`, same pattern as Ledger). Legacy document columns on the main row are not on the form — use documents API. |
| EmployeeDocument | `/employees/:id/documents`, `PUT /documents/:docId`, `GET /documents/expiries` | Nested under employee; no flat list of all documents (only expiries + per-employee on GET employee). Needs a mini-surface or employee-form Documents tab, not pure 7-file EMR. |
| ~~LeaveAllocation~~ | `POST /leave/allocations`, `GET /employees/:id/leave-allocations` | **Shipped** as `employee_leave_allocation`. Custom surface (not flat EMR list): pick employee + year, list balances, create allocate form. **BE-009** fixed `employee_id` on create schema. Still no global list / update / delete. |
| ~~LeavePolicy~~ | `/leave/policies` | **Shipped** create-only (`supportsUpdate`/`supportsDelete: false`); get-by-id scans list. |
| ~~LeaveRequest~~ | `/leave-requests` + nested create | **Shipped** custom repository (nested create + status PUT). Not a full DocumentSurface workflow. |
| ~~ShiftMaster~~ | `/shifts` | **Shipped** create-only; get-by-id scans list. |
| EmployeeShiftAssignment | `POST /employees/:id/shift` | Nested under employee; no global list. |
| AttendanceDetails | `POST /employees/:id/attendance`, roster GET | Nested / roster-shaped; not a flat master list. |
| PayslipMain | `/payslips` | List-by-period requires `startDate`/`endDate` query params; create uses legacy string `Employee_Id`. Needs dedicated list UX. |
| SalaryRevisionHistory | salary-revisions | Append-only audit; also auto-created on employee salary save. List is per-employee only. |

## Organization module (found while registering Wave A5's Organization batch)

| Entity | Backend path | Reason deferred |
|---|---|---|
| ~~CurrencyRate~~ | `/organization/rates` | **Shipped** as `organization_currency_rate`. Backend added `GET /rates/history` + `GET /rates/:id`; lookup `GET /rates?currencyId&date` remains. Append-only (`supportsUpdate`/`supportsDelete: false`). Custom repository for path split. |
| ~~ConfigSetting~~ | `/organization/config` | **Shipped** as `organization_config`. List is a full array; update `PUT /config/:key` with `{value}`; list/edit by int row id, wire key for PUT. No create/delete. |
| ~~VoucherSeries~~ | `/organization/voucher-series` | **Shipped** as `organization_voucher_series`. `company_id` remains plain int (CompanyProfile deferred); branch + FY are optional FKs. `require_approval` toggles optional SI approval workflow. |
| ~~UserCredentials~~ | `/organization/users` | **Shipped** as `organization_user` — password write-only; multi-FK contact/role/branch; custom create/update bodies. |
| ~~ProjectMaster~~ | `/organization/projects` | **Shipped** as `organization_project` with `FieldType.selfFk` parent + contact/ledger/godown FKs; coordinator employee still plain int (HR not shipped). |
| ~~CompanyProfile~~ | `/organization/companies` + `/company/:id` | **Shipped** as `organization_company` — list+edit, logo out-of-band, `supportsDelete: false`, no EMR create (provision is separate POST). |
| ExtraValuesTable | `/organization/extras/:type/:objectId` | Polymorphic KV keyed by `(TYPE, OBJECT_ID)` — not a flat master list; keep deferred until a host entity needs custom attributes. |
| ~~AuditLog~~ | `/organization/audit-logs` | **Shipped** as `organization_audit` — read-only list. |
| ~~ErrorReporting~~ | `/organization/error-reports` | **Shipped** as `organization_error_report` — list + create; no get/update/delete. |

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

Still deferred for reasons the flag doesn't reach:
- **ItemImage** — the missing `PUT` is now fixable via `supportsUpdate: false`, but the
  `ImageBase64` field still has no `FieldType` to render it with; a form that can create
  records but never set their actual payload isn't worth shipping. Revisit when
  `FieldType.binary` exists.

One list-endpoint gap (PriceListEntry) was also seen once — not yet cross-cutting, but watch for
a second occurrence before deciding whether it needs its own manifest flag.
