# Master List/FormBloc → EMR migration checklist

> **Last updated:** 2026-07-15  
> **Ground truth:** `lib/features/**` list/form pages and `bloc/` folders  
> **Done shape:** [`manifest-spec.md`](./manifest-spec.md) · reference package `employee_department`  
> **Living status board:** [`STATUS.md`](./STATUS.md)

The generic EMR path (`CrudBloc` + `MasterListSurface` / `MasterFormSurface`) is **built and used by many newer masters**, but a set of early masters still run on hand-written `*ListBloc` / `*FormBloc`. Some packages have both: DI exposes `createXCrudBloc`, while presentation still wires the old blocs.

This document is the concrete per-package work queue for finishing that migration. It is **not** about vouchers, auth, desk, or reports.

---

## Definition of done (per master)

| Layer | Target |
|-------|--------|
| List | `CrudBloc<E, ID, F>` + `MasterListSurface` |
| Form | `Repository` + `DetailBloc` (edit) + `MasterFormSurface` (or a documented tabbed shell that still uses core, not a hand-rolled list engine) |
| Feature package | No per-entity `*_list_*` / `*_form_*` bloc files |
| DI | Keep `createXRepository` / `createXCrudBloc` / `xCrudBloc` + `CrudBlocScope` |

**Reference implementation:**

- `lib/features/employee_department/presentation/department_list_page.dart`
- `lib/features/employee_department/presentation/department_form_page.dart`
- `lib/features/employee_department/department_di.dart`

**Already true for every MIGRATE master below:** manifest exists; `create*CrudBloc` + `*CrudBloc(context)` exist. Work is mostly **rewire presentation + delete legacy blocs**.

---

## Status legend

| Tag | Meaning |
|-----|---------|
| **DONE** | EMR list + form (or list-only where intended) |
| **MIGRATE** | Still on feature `*ListBloc` / `*FormBloc` |
| **KEEP** | Intentionally custom (not EMR masters) |
| **OPTIONAL** | EMR list done; form is custom shell — leave unless unifying tabbed forms |

---

## Mechanical recipe (every MIGRATE package)

Do these in order; stop if smoke fails.

1. **List page** — replace with the Department pattern:
   - `BlocProvider<CrudBloc<E, int, void>>.value(value: xCrudBloc(context), …)`
   - `MasterListSurface` with `manifest`, `idOf`, `onCreate`, `onTap`
   - Drop hand-built list UI, search field, delete handlers, export wiring (surface owns export when `supportsExport`)
2. **Form page** — replace with the Department pattern:
   - `RepositoryProvider` → `MasterFormSurface`
   - Edit: wrap with `DetailBloc`
   - On save/delete: `xCrudBloc(context).add(const CrudRefreshRequested())` then `context.go(resourcePath)`  
     (**do not** re-fire `CrudItemCreated` / update / delete — the surface already persisted)
3. **Flags** — confirm manifest: `supportsUpdate` / `supportsDelete` / `hardDelete` / FKs match backend
4. **Delete** entire `bloc/` list+form files (6 files typical)
5. **Imports** — nothing outside the package should import deleted blocs
6. **Smoke** — list load, search, create, edit, delete (if allowed), back-navigation shows new/updated row
7. **Tests** — keep mapper tests; no package-level list/form bloc tests for these masters (core surfaces cover the engine)
8. **Format/analyze** — `dart format` on touched files; `flutter analyze` clean on the package

---

## Wave A — Flat masters (lowest risk)

Same shape as Brand/Department. **Ship order: Brand first** (canonical demo), then the rest.

| # | Package | Route area | Delete after | Checklist |
|---|---------|------------|--------------|-----------|
| A1 | `inventory_brand` | `/inventory/brand` | ~~`bloc/brand_*` (6)~~ deleted | [x] list→EMR [x] form→EMR [x] delete blocs [ ] smoke (manual) — `hardDelete: true` |
| A2 | `inventory_category` | `/inventory/category` | ~~`bloc/category_*` (6)~~ deleted | [x] list [x] form [x] delete [ ] smoke (`hardDelete`) |
| A3 | `inventory_uom` | `/inventory/uom` | ~~`bloc/uom_*` (6)~~ deleted | [x] list [x] form [x] delete [ ] smoke (`hardDelete`) |
| A4 | `inventory_godown` | `/inventory/godown` | ~~`bloc/godown_*` (6)~~ deleted | [x] list [x] form [x] delete [ ] smoke (`hardDelete`) |
| A5 | `inventory_item_property` | `/inventory/property` | ~~`bloc/item_property_*` (6)~~ deleted | [x] list [x] form [x] delete [ ] smoke — **`supportsUpdate: false`** |
| A6 | `organization_address_book` | `/organization/contacts` | 6 × address_book_* | [ ] list [ ] form [ ] delete [ ] smoke |

**Per-package exit:** no list/form `bloc/` files, list/form pages thin (≈ Department size), `create*CrudBloc` still used via scope.

---

## Wave B — FK / selfFk masters

Same EMR recipe; verify FK closures and self-exclude on parent pickers after rewire.

| # | Package | Extra care | Delete after | Checklist |
|---|---------|------------|--------------|-----------|
| B1 | `inventory_sku` | FK → Item; hard delete | 6 × sku_master_* | [ ] list [ ] form [ ] FK picker [ ] delete [ ] smoke |
| B2 | `inventory_group` | `FieldType.selfFk` parent | 6 × inventory_group_* | [ ] list [ ] form [ ] self exclude [ ] delete [ ] smoke |
| B3 | `accounts_account_group` | selfFk parent | 6 × account_group_* | [ ] list [ ] form [ ] self exclude [ ] delete [ ] smoke |
| B4 | `inventory_item` | group FK; larger form | 6 × inventory_item_* | [ ] list [ ] form [ ] FK [ ] delete [ ] smoke |

**Exit:** create/edit with parent/item FK resolves; no cycle-picker bugs on groups.

---

## Wave C — Tabbed / nested-save masters (higher risk)

List can go to `MasterListSurface` immediately. Forms may need an **Employee-style** custom shell (FieldRenderer + tabs), not a dumb paste of the Department form.

| # | Package | List | Form strategy | Delete | Checklist |
|---|---------|------|---------------|--------|-----------|
| C1 | `accounts_ledger` | → EMR | Prefer port of `employee_form_page` pattern (Core/Bank/Credit/Tax tabs + nested payload); **not** thin MasterForm only if tabs/nested save would regress | 6 × ledger_* list+form | [ ] list EMR [ ] form: MasterForm if tabs fit `FormLayout.tabs` **or** employee-like shell without `LedgerFormBloc` [ ] nested bank/credit/tax save [ ] delete list+form blocs [ ] smoke all tabs |
| C2 | `organization_user` | → EMR | Password write-only; multi-FK; custom create/update bodies — keep special encode if needed, drop List/FormBloc | 6 × user_credentials_* | [ ] list EMR [ ] form EMR or thin custom [ ] password not echoed [ ] role/branch/contact FKs [ ] delete blocs [ ] smoke |

### Related (already OK on list)

| Package | Status | Action |
|---------|--------|--------|
| `employee_employee` | EMR list + custom tabbed form | **OPTIONAL** — no list/form bloc folder; leave form unless unifying with Ledger |
| `employee_leave_allocation` | Custom list/form (no global list API) | **KEEP** — exception; do not force CrudBloc |

---

## Wave D — Already DONE (no migration)

Verify only if you touch them; no `*ListBloc` / `*FormBloc` cleanup required.

| Package | Notes |
|---------|--------|
| `employee_department` | Canonical DONE (reference pages) |
| `inventory_brand` | DONE (PR1) — was Wave A1 |
| `inventory_category` | DONE (PR2) — was Wave A2 |
| `inventory_uom` | DONE (PR2) — was Wave A3 |
| `inventory_godown` | DONE (PR2) — was Wave A4 |
| `inventory_item_property` | DONE (PR2) — was Wave A5; `supportsUpdate: false` |
| `employee_designation` | FK dept |
| `employee_leave_policy` | create-only flags |
| `employee_leave_request` | EMR (+ approve/reject UX as needed) |
| `employee_shift` | create-only |
| `inventory_batch` | FK item |
| `inventory_pricelist` | EMR |
| `inventory_route` | EMR |
| `inventory_tax_category` | EMR |
| `inventory_uom_conversion` | EMR |
| `organization_audit` | list-only |
| `organization_branch` | EMR |
| `organization_company` | EMR |
| `organization_config` | EMR |
| `organization_currency` | EMR |
| `organization_currency_rate` | EMR |
| `organization_error_report` | EMR |
| `organization_financial_year` | no delete |
| `organization_project` | selfFk + FKs |
| `organization_user_role` | EMR list/form; **KEEP** `bloc/role_permissions_*` (matrix admin) |
| `organization_voucher_series` | EMR (confirm shared `CrudBlocScope` if list/form must share cache) |

---

## Wave E — KEEP forever (not EMR bloc migration)

Do **not** convert these to master CrudBloc/list surface as this migration.

| Package | Blocs | Reason |
|---------|-------|--------|
| `auth` | `AuthBloc` | Session bootstrap |
| `desk` | `DeskCubit` | Dashboard |
| `reports` | `report_viewer_*`, `reports_hub_*` | Report archetype |
| `organization_user_role` (partial) | `role_permissions_*` | Permission matrix UI |
| `transactions_sales_invoice` | list/form/detail blocs | Document gold standard |
| `transactions_item_qty` | list/detail | Voucher family |
| `transactions_ledger_amount` | list/detail | Payment/Receipt |
| `transactions_debit_credit` | list/detail | Journal/Contra |
| `transactions_stock` | list/detail | Stock vouchers |

**Optional later (out of scope here):** consolidate voucher list/detail into shared document blocs so SI and families share one engine — that is **voucher unification**, not EMR master migration.

---

## Roll-up tracker

### MIGRATE masters (12) — work queue

| Wave | Package | List | Form | Bloc files to remove | Priority |
|------|---------|------|------|----------------------|----------|
| A1 | `inventory_brand` | ListBloc | FormBloc | 6 | **P0 — template** |
| A2 | `inventory_category` | ListBloc | FormBloc | 6 | P1 |
| A3 | `inventory_uom` | ListBloc | FormBloc | 6 | P1 |
| A4 | `inventory_godown` | ListBloc | FormBloc | 6 | P1 |
| A5 | `inventory_item_property` | ListBloc | FormBloc | 6 | P1 |
| A6 | `organization_address_book` | ListBloc | FormBloc | 6 | P1 |
| B1 | `inventory_sku` | ListBloc | FormBloc | 6 | P1 |
| B2 | `inventory_group` | ListBloc | FormBloc | 6 | P1 |
| B3 | `accounts_account_group` | ListBloc | FormBloc | 6 | P1 |
| B4 | `inventory_item` | ListBloc | FormBloc | 6 | P1 |
| C1 | `accounts_ledger` | ListBloc | FormBloc (tabbed) | 6 | P2 |
| C2 | `organization_user` | ListBloc | FormBloc (special) | 6 | P2 |

**Total debt:** ~42 hand-written bloc files across 7 remaining master packages (A6 + Wave B–C).

### Counts (snapshot 2026-07-15, post-PR2)

| Bucket | Count |
|--------|------:|
| MIGRATE masters | 7 (A1–A5 code done) |
| DONE masters | ~27 |
| KEEP special (auth/desk/reports/vouchers/leave allocation/role matrix) | see Wave E |

---

## Brand (A1) — expanded file checklist

**Status: code complete (PR1).** Use as the template for A2–A6.

| File | Action |
|------|--------|
| `presentation/brand_list_page.dart` | **Done** — `CrudBloc` + `MasterListSurface` |
| `presentation/brand_form_page.dart` | **Done** — `Repository` + `DetailBloc` (edit) + `MasterFormSurface`; refresh via `brandCrudBloc` |
| `brand_di.dart` | **Kept** (`createBrandRepository`, `createBrandCrudBloc`, `brandCrudBloc`) |
| `brand_manifest.dart` | **Kept** (`hardDelete: true`) |
| `domain/`, `data/` | **Kept** |
| `bloc/brand_list_*` + `bloc/brand_form_*` (6) | **Deleted** (folder removed) |
| Router / menu | No change |
| Tests | `test/features/inventory_brand/brand_mapper_test.dart` keep |

**Smoke (manual):** login → Inventory → Brands → search → create → appears on list → edit → delete (hard) → gone.

---

## Suggested PR slicing

| PR | Scope |
|----|--------|
| **PR1** | Brand only — **code done**; manual smoke remaining |
| **PR2** | Category, UOM, Godown, ItemProperty — **code done**; manual smoke remaining |
| **PR3** | AddressBook |
| **PR4** | SKU, InventoryGroup, AccountGroup |
| **PR5** | InventoryItem |
| **PR6** | Ledger (tabbed) |
| **PR7** | Users (credentials) |

Do not mix voucher packages into these PRs.

---

## Definition of “migration completed” (repo-wide)

- [ ] All remaining MIGRATE masters (7 after PR1–PR2) are EMR (or documented C1/C2 exception with no ListBloc)
- [ ] Zero `*_list_bloc.dart` / `*_form_bloc.dart` under master feature packages
- [ ] Remaining `bloc/` dirs only: auth, reports, role_permissions, voucher packages
- [ ] This checklist’s Wave A–C boxes closed; [`STATUS.md`](./STATUS.md) notes migration complete
- [ ] Brand docs/comments no longer claim Brand is the EMR proving ground while still using ListBloc

---

## Out of scope

- ManifestRegistry / generic `/m/:id` routes  
- Offline/sync  
- Voucher DocumentSurface consolidation  
- `FieldType.binary` / ItemImage  

Those are separate tracks. See [`manifest-exceptions.md`](./manifest-exceptions.md), [`BUILD_TASKS_V2.md`](./BUILD_TASKS_V2.md), and [`backend-suggestions.md`](./backend-suggestions.md).
