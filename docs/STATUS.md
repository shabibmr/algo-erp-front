# algoERP Frontend — Living Status

> **Last updated:** 2026-07-13 (Sprint F: leave allocation + BE-009 employee_id)  
> **Code ground truth:** `lib/features/**`, `lib/core/**`  
> **Required surface area:** [`feature-inventory.md`](./feature-inventory.md)  
> **Deferred entities:** [`manifest-exceptions.md`](./manifest-exceptions.md)  
> **Recipe:** [`manifest-spec.md`](./manifest-spec.md)  
> **Execution plan (wave narrative):** [`BUILD_TASKS_V2.md`](./BUILD_TASKS_V2.md)

Legend:

| Mark | Meaning |
|------|---------|
| `[x]` | Shipped in frontend (list + form/create path via EMR unless noted) |
| `[~]` | Partial shell / UI only / incomplete behaviour |
| `[!]` | Documented exception — blocked on EMR gap, backend shape, or dependency |
| `[ ]` | Not started |
| `P` | Parked (explicit non-goal for online-first track) |

**Architecture (current):** online-only, interface-driven repositories, manifest-rendered masters. Offline/sync stays parked.

---

## Architecture (one page)

### Layering

```
┌──────────────────────────────────────────────────────────────────┐
│  Presentation                                                     │
│  AppShell · go_router · AuthBloc · thin *ListPage/*FormPage       │
│  MasterListSurface · MasterFormSurface · (future DocumentSurface) │
└────────────────────────────┬─────────────────────────────────────┘
                             │ RepositoryProvider / BlocProvider
┌────────────────────────────▼─────────────────────────────────────┐
│  Domain                                                           │
│  Entity · Repository<E,ID> · PageQuery · UseCase                  │
│  (future: Decimal Line Engine · VoucherBlueprint)               │
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│  Data                                                             │
│  DTO + Mapper · RemoteDataSourceBase · RemoteRepository           │
│  DioClient (+ auth / tenant / request-id interceptors)            │
└────────────────────────────┬─────────────────────────────────────┘
                             │ HTTPS
┌────────────────────────────▼─────────────────────────────────────┐
│  Backend (algo-backend)                                           │
│  /auth · /organization · /accounts · /inventory · /employee       │
│  /transactions · /reports                                         │
└──────────────────────────────────────────────────────────────────┘

Parked (not on the request path today):
  lib/core/database/**  (drift tables, outbox) · lib/core/sync/**
```

### EMR flow (masters)

```
  EntityManifest<E>          formFields / listColumns / rbac / path
         │
         ├─► MasterListSurface  ◄── CrudBloc  ◄── Repository
         │         │
         │         └─ AdaptiveEntityList · FilterBar · PermissionGate
         │
         └─► MasterFormSurface  ◄── DetailBloc (edit) · Repository
                   │
                   └─ FieldRenderer(FieldType) · FormMixin errors
```

**Feature package cost (flat master):** 7 files + 2 router routes + 1 menu item.  
No per-entity list/form widgets. See [`manifest-spec.md`](./manifest-spec.md).

### Archetypes

| Archetype | Engine | Example |
|-----------|--------|---------|
| Master-CRUD | `EntityManifest` + list/form surfaces | Brand, Designation |
| Voucher document | `VoucherBlueprint` + DocumentSurface (**not built**) | SalesInvoice |
| Report | `ReportDefinition` + ReportViewer (**not built**) | Trial balance |
| Workflow (non-GL) | Treat as master or mini-surface later | LeaveRequest |

### Dependency direction (must hold)

- Features depend **inward** on `core/domain` + `core/surfaces` + `core/manifest`.
- Features **must not** introduce a new `CrudBloc` subclass or list table widget.
- Cross-module FKs (e.g. Item → Ledger) resolve via **another module’s** `createXRepository` / shared factory — not by importing presentation pages. Pattern proven: Designation → Department (`designation_manifest.dart`).

### Critical path (product)

```
  [x] Auth + shell
  [x] EMR list/form + 18 masters
  [x] AccountGroup (+ parent selfFk) + Ledger    ── Sprint A core
  [x] FieldType.selfFk + InventoryGroup          ── unblocks item groups
  [x] Ledger bank/credit/tax tabs                ── Sprint A phase 2
  [ ] Dept parent                                ── optional
  [x] InventoryItem + SKU + Batch + group FK     ── Sprint B
  [x] Line Engine + DocumentSurface + SI gold    ── Sprint C
  [x] Item-qty trading family (Q/SO/DN/PO/RN/PI/CN/DN) ── Sprint D
  [x] Payment + Receipt (ledgerAmount engine)            ── Sprint D
  [x] Journal + Contra (debitCredit engine)              ── Sprint D
  [x] Stock vouchers GT/MI/RQ/SR                         ── Sprint D done
  [x] Org access (company, users, role matrix)           ── Sprint E
  [~] HR depth (employee + leave + shift; attendance/payslip later) ── F
  [ ] Reports · palette                                  ── G
  [P] Offline sync
```

---

## 0. Scorecard (at a glance)

| Layer | Progress | Notes |
|-------|----------|-------|
| Platform (shell, network, auth, widgets) | ~90% | Matrix RBAC; no command palette |
| EMR runtime (list/form/FK) | ~75% | selfFk shipped; still missing binary, registry, ClientQuery |
| Organization masters | **13 / ~14** | Full masters; extras polymorphic still deferred |
| Inventory masters | **13 / ~20** | Flat + Item/Group/SKU/Batch; image still deferred |
| Employee masters | **7 / ~14** | + LeaveAllocation (per-employee list/create; BE-009) |
| Accounts masters | **2 / ~8** | AccountGroup (selfFk parent) + Ledger core |
| Vouchers / documents | **17 / ~17** | Full Sprint D voucher matrix (SI gold + 16 kinds) |
| Reports / dashboard data | ~5% | Desk shell + empty invitations |
| Offline / sync | `P` | Scaffold only under `lib/core/database/**` |
| **ERP end-to-end usability** | **Early mid** | Party + item masters; still no documents |

**Shipped master packages (30+):** Brand, UOM, Category, TaxCategory, Godown, RouteMaster, UOMConversion, PriceList, ItemProperty, Department, Designation, Employee, LeavePolicy, LeaveAllocation, LeaveRequest, Shift, Branch, Currency, CurrencyRate, UserRole, AddressBook, FinancialYear, AccountGroup, Ledger, InventoryItem, SKU, Batch, InventoryGroup, Company, Users, Project, Config, AuditLog, ErrorReport, VoucherSeries.  
Plus **Auth** (full) and **Today’s Desk** (shell).

---

## 1. Platform & core

| Component | Path / area | Status | Notes |
|-----------|-------------|--------|-------|
| Flavors / entrypoints | `main_*.dart` | `[x]` | dev / staging / prod |
| DI | `core/di` | `[x]` | get_it + injectable |
| Design tokens + theme | `core/theme` | `[x]` | light/dark, motion, preview |
| l10n en + ar | `lib/l10n` | `[x]` | ARB + gen |
| Adaptive shell + menu | `core/navigation` | `[x]` | Some menu routes still placeholders |
| Network (Dio + interceptors) | `core/network` | `[x]` | auth, tenant, request-id |
| Failure + safeCall | `core/error` | `[x]` | |
| Wave-0 contracts | `feature-contract.md` | `[x]` | Frozen interfaces |
| RemoteRepository engine | `core/data` | `[x]` | |
| CrudBloc / DetailBloc | `core/bloc` | `[x]` | |
| FormMixin | `core/bloc/form_mixin.dart` | `[x]` | Submit lifecycle still thin |
| `buildRepository` | `core/di/repo_binding.dart` | `[x]` | |
| Auth stack | `features/auth` | `[x]` | Login, me, change-password, guards |
| PermissionService | `core/auth` | `[x]` | MatrixPermissionService (BE-001); role matrix admin UI |
| Widget library + gallery | `core/widgets` | `[x]` | Catalog + `/widget-gallery` |
| MasterListSurface | `core/surfaces` | `[x]` | |
| MasterFormSurface | `core/surfaces` | `[x]` | Doubles as read-only view |
| FieldRenderer | `core/manifest` | `[x]` | text/int/decimal/bool/dateTime/fk/selfFk |
| FieldType.selfFk | | `[x]` | Self exclude in picker; InvGroup + AccountGroup |
| FieldType.binary / image | | `[ ]` | Logo, ItemImage |
| FieldType.enum | | `[ ]` | Free-string enums today |
| ManifestRegistry | | `[ ]` | Hand-wired routes/menu |
| Generic `/m/:id` routes | | `[ ]` | Per-entity routes today |
| ClientQuery (client search/sort) | | `[ ]` | BE-002–004 workaround |
| Idempotency-Key interceptor | | `[ ]` | See CR-004 / BE-005 |
| Command palette | shell header stub | `[ ]` | Tooltip “coming soon” |
| DocumentSurface + Line Engine | `core/domain/line_engine`, `core/surfaces` | `[x]` | SI gold; expand lifecycle later |
| Report framework | | `[ ]` | |
| Offline DB / outbox / sync | `core/database`, `core/sync` | `P` | Parked |

---

## 2. Domain matrix vs `feature-inventory.md`

### 2.1 Organization & system

| Entity | API area | Status | Package / note |
|--------|----------|--------|----------------|
| CompanyProfile | `/organization/companies` | `[x]` | List+edit; logo out-of-band; no delete/create |
| FinancialYear | `/organization/fy` | `[x]` | `organization_financial_year` · `supportsDelete: false` |
| Branch | `/organization/branches` | `[x]` | `organization_branch` |
| Currency | `/organization/currencies` | `[x]` | `organization_currency` |
| CurrencyRate | `/organization/rates` | `[x]` | `organization_currency_rate` · list/history + create; append-only |
| VoucherSeries | `/organization/voucher-series` | `[x]` | `organization_voucher_series` · require_approval; company id int |
| UserRole | `/organization/roles` | `[x]` | `organization_user_role` |
| UserAccessPermission | `/roles/:id/permissions` | `[x]` | Matrix UI + GET/PUT admin |
| UserCredentials | `/organization/users` | `[x]` | Password write-only; contact/role/branch FKs |
| AddressBook | `/organization/contacts` | `[x]` | `organization_address_book` |
| ConfigSetting | `/organization/config` | `[x]` | `organization_config` · list+edit value; no create/delete |
| ProjectMaster | `/organization/projects` | `[x]` | `organization_project` · selfFk parent + contact/ledger/godown FKs |
| AuditLog | `/organization/audit-logs` | `[x]` | `organization_audit` · read-only list |
| ErrorReporting | `/organization/error-reports` | `[x]` | `organization_error_report` · list+create |
| ExtraValuesTable | `/organization/extras/...` | `[!]` | Polymorphic KV — stays deferred |
| Org hub route | `/organization` | `[x]` | Binder has hub only; masters are hub tiles (`AppMenu.organizationMasters`) |

### 2.2 Accounts

| Entity | API area | Status | Note |
|--------|----------|--------|------|
| AccountGroup | `/accounts/groups` | `[x]` | `accounts_account_group` · selfFk parent |
| LedgerMaster | `/accounts/ledgers` | `[x]` | Core + bank/credit/tax tabs; nested save |
| LedgerBankDetails | nested `bankDetails` | `[x]` | Tab on ledger form (not separate menu) |
| LedgerCreditSettings | nested `creditSettings` | `[x]` | Tab on ledger form |
| LedgerTaxSettings | nested `taxSettings` | `[x]` | Tab on ledger form |
| BillwiseRecord | `/accounts/billwise` | `[ ]` | Settlement-related |
| ChequeDetails | `/accounts/cheque` | `[ ]` | |
| Outstanding / aging | `/outstanding`, `/aging` | `[ ]` | Report-ish |
| Accounts hub | `/accounts` | `[~]` | Placeholder |

### 2.3 Inventory

| Entity | API area | Status | Package / note |
|--------|----------|--------|----------------|
| UOM | `/inventory/uom` | `[x]` | `inventory_uom` |
| InventoryGroup | `/inventory/group` | `[x]` | `inventory_group` · selfFk parent |
| Brand | `/inventory/brand` | `[x]` | `inventory_brand` · hard delete |
| Category | `/inventory/category` | `[x]` | `inventory_category` · hard delete |
| TaxCategories | `/inventory/tax-category` | `[x]` | `inventory_tax_category` |
| InventoryItem | `/inventory/item` | `[x]` | `inventory_item` · incl. group FK |
| SKUMaster | `/inventory/sku` | `[x]` | `inventory_sku` · hard delete · FK Item |
| ItemBatch | `/inventory/batch` | `[x]` | `inventory_batch` · soft delete · FK Item |
| ItemProperty | `/inventory/property` | `[x]` | `supportsUpdate: false` |
| ItemImage | `/inventory/image` | `[!]` | binary + no PUT value |
| LedgerItemMapping | `/ledger-item-mapping` | `[!]` | Cross-module / no PUT |
| Ingredient (BOM) | `/inventory/ingredient` | `[!]` | Dual FK → same target |
| Godown | `/inventory/godown` | `[x]` | `inventory_godown` |
| StockLedger | stock-ledger GETs | `[ ]` | Read-only views |
| Stock balance | stock-balance GETs | `[ ]` | |
| UOMConversion | `/inventory/conversion` | `[x]` | `inventory_uom_conversion` |
| PriceList | `/inventory/pricelist` | `[x]` | `inventory_pricelist` |
| PriceListEntry | `/pricelist-entry` | `[!]` | No list endpoint |
| RouteMaster | `/inventory/route` | `[x]` | `inventory_route` |
| RouteCustomerMapping | route/customer-mapping | `[!]` | Cross-module |
| RouteMapping | route/mapping | `[!]` | Cross-module |
| Inventory hub | `/inventory` | `[~]` | Placeholder |

### 2.4 Employee (HR)

| Entity | API area | Status | Package / note |
|--------|----------|--------|----------------|
| Department | `/employee/departments` | `[x]` | `employee_department` |
| Designation | `/employee/designations` | `[x]` | `employee_designation` · FK dept |
| EmployeeDetails | `/employee/employees` | `[x]` | `employee_employee` · Core/Bank/Salary tabs |
| EmployeeDocument | documents routes | `[ ]` | Nested create; expiries list later |
| EmployeeBankDetails | nested on employee | `[x]` | Tab on employee form (not separate menu) |
| EmployeeSalaryDetails | nested on employee | `[x]` | Tab on employee form |
| SalaryRevisionHistory | | `[ ]` | Append-only; auto on salary save server-side |
| LeavePolicy | `/leave/policies` | `[x]` | `employee_leave_policy` · create-only API |
| LeaveAllocation | allocations | `[x]` | `employee_leave_allocation` · per-employee+year list; create (BE-009) |
| LeaveRequest | leave-requests | `[x]` | `employee_leave_request` · approve/reject/cancel |
| AttendanceDetails | attendance | `[ ]` | Nested log + roster per employee |
| ShiftMaster | `/shifts` | `[x]` | `employee_shift` · create-only API |
| EmployeeShiftAssignment | | `[ ]` | Nested assign under employee |
| PayslipMain | payslips | `[ ]` | Voucher-like; period list needs query params |
| Employee hub | `/employee` | `[~]` | Placeholder; masters on binder |

### 2.5 Transactions (vouchers)

All types share **header + main + lines + lifecycle**. DocumentSurface + Line Engine exist; clone via blueprint recipe.

| voucher_type | Status | Notes |
|--------------|--------|-------|
| SalesInvoice | `[x]` | List filters, draft/post/edit, detail, lifecycle, print, post&book |
| PurchaseInvoice | `[x]` | Shared item-qty engine · list/create/detail/cancel |
| Payment | `[x]` | ledgerAmount engine · cash/bank + lines · list/create/detail/cancel |
| Receipt | `[x]` | same engine · list/create/detail/cancel |
| Contra | `[x]` | debitCredit engine · amount + DR/CR · list/create/detail/cancel |
| Journal | `[x]` | debitCredit engine · debit/credit cols · list/create/detail/cancel |
| CreditNote | `[x]` | item-qty · party `ledger_id` · list/create/detail/cancel |
| DebitNote | `[x]` | item-qty · party `ledger_id` · list/create/detail/cancel |
| Quotation | `[x]` | item-qty · list/create/detail/cancel |
| SalesOrder | `[x]` | item-qty · list/create/detail/cancel |
| PurchaseOrder | `[x]` | item-qty · list/create/detail/cancel |
| DeliveryNote | `[x]` | item-qty · optional SO conversion · stock out |
| ReceiptNote | `[x]` | item-qty · optional PO conversion · stock in |
| GodownTransfer | `[x]` | stock engine · from/to godown · list/create/detail/cancel |
| MaterialIn | `[x]` | stock engine · cr/dr qty lines |
| Requirement | `[x]` | stock engine · item qty (no godown) |
| StockRequest | `[x]` | stock engine · request qty; fulfill UI later |
| Lifecycle (edit/approve/reject/cancel) | `[~]` | Cancel wired on item-qty kinds; full generic toolbar later |
| TermsAndConditions | `[ ]` | Ancillary master |
| TransportationDetails | `[ ]` | Ancillary master |
| Transactions hub | `/transactions` | `[~]` | Placeholder |

### 2.6 Reports & desk

| Surface | API | Status |
|---------|-----|--------|
| Today’s desk | — | `[~]` | Layout live; no live KPIs/queues |
| Dashboard summary | `/reports/dashboard` | `[ ]` |
| Alerts | `/reports/alerts` | `[ ]` |
| Global search | `/reports/search` | `[ ]` |
| Sales / purchase register | `/transactions/reports/...` | `[ ]` |
| Stock summary / valuation | | `[ ]` |
| VAT return | | `[ ]` |
| Trial balance / P&L / BS / day-book | | `[ ]` |
| Ledger statement | | `[ ]` |
| Aging | `/accounts/aging` | `[ ]` |
| HR summaries / overtime | employee reports | `[ ]` |
| Reports hub | `/reports` | `[~]` | Placeholder |
| Settings | `/settings` | `[~]` | Placeholder |

### 2.7 Auth & product chrome

| Item | Status |
|------|--------|
| Login / logout / session restore | `[x]` |
| Change password | `[x]` |
| Router auth redirect | `[x]` |
| 403 page | `[x]` |
| Session context bar (company/branch/FY) | `[~]` | FY still placeholder |
| Theme preview | `[x]` |
| Widget gallery | `[x]` |

---

## 3. Backend frictions that still shape the plan

From `backend-suggestions.md` / feature contract (still active):

| ID | Gap | Frontend impact |
|----|-----|-----------------|
| BE-001 | Permission matrix read | **Done** — `GET /auth/permissions` + role admin GET/PUT |
| BE-002–004 | No search/filter/sort | ClientQuery deferred; params forwarded no-op |
| BE-005 | No idempotency keys | Client should send keys; don’t auto-retry mutates |
| BE-008 | No lightweight lookup DTOs | FK uses full list + projection |

Entity-level backend gaps live in [`manifest-exceptions.md`](./manifest-exceptions.md).

---

## 4. Recommended build order

Goal: unlock **real trading workflow** (party + item + sales invoice) before mass-stamping remaining HR/ancillary masters.

### Sprint A — Unblock ledgers & parties (1–2 weeks)

| # | Work | Why |
|---|------|-----|
| A1 | **LedgerMaster** (list + core form; bank/credit/tax as form sections or follow-ups) | Customer/supplier/cash/bank for vouchers |
| A2 | **AccountGroup** — needs `FieldType.selfFk` + tree picker | Ledger parent hierarchy |
| A3 | Cross-module **FK repository injection pattern** (document in manifest-spec) | Item → ledger, route → employee later |
| A4 | Optional: **ClientQuery** on list surface for usable search | Day-to-day master UX |

*Parallel:* polish session context (branch/FY) if API claims exist.

### Sprint B — Inventory sellable catalogue

| # | Work | Why |
|---|------|-----|
| B1 | **InventoryGroup** (after selfFk) | Item classification |
| B2 | **InventoryItem** (phased fields: identity, UOM, brand, category, tax, stock flags first; GL FKs second) | Invoice lines need items |
| B3 | SKU / Batch as needed by posting rules | Only if invoice lines require them early |
| B4 | Stock balance **read-only** views | Ops confidence |

### Sprint C — Document stack (critical path)

| # | Work | Status |
|---|------|--------|
| C1 | Decimal **Line Engine** (pure Dart + tests) | `[x]` |
| C2 | **VoucherBlueprint** model | `[x]` (SI seed) |
| C3 | **DocumentSurface** (header, lines, totals, post) | `[x]` MVP |
| C4 | **Sales Invoice gold** list + post online | `[x]` |
| C5 | Recipe docs | `[x]` `docs/templates/*` |
| — | SI detail / cancel / approve UI | `[x]` |
| — | SI Quotation/SO conversion, salesperson/project, batch picker | `[x]` |
| — | SI server HTML PDF (auth via Dio) | `[x]` route `/…/pdf` |
| — | Backend book-on-approve (SI Draft/Approved→Posted) | `[x]` `bookSalesInvoiceIfUnposted` |

### Sprint D — Register high-value voucher family

Order after Sales Invoice:

1. ~~Quotation → SalesOrder → DeliveryNote (pre-sales chain)~~ **`[x]`**  
2. ~~PurchaseOrder → ReceiptNote → PurchaseInvoice~~ **`[x]`**  
3. ~~Payment / Receipt~~ **`[x]`** `ledgerAmount` engine (no billwise allocation UI yet — honest list/post only)  
4. ~~CreditNote / DebitNote~~ **`[x]`** item-qty + `ledger_id` party field  
5. ~~Journal / Contra~~ **`[x]`** `debitCredit` engine (client balance check)  
6. ~~GodownTransfer / MaterialIn / Requirement / StockRequest~~ **`[x]`** stock engine  

**Sprint D complete** for registered voucher types (SI remains gold-depth).  

**Shared stacks:**  
- Item-qty: `lib/core/vouchers/item_qty/*` + `transactions_item_qty` (8 kinds)  
- Ledger-amount: `lib/core/vouchers/ledger_amount/*` + `transactions_ledger_amount` (Payment, Receipt)  
- Debit-credit: `lib/core/vouchers/debit_credit/*` + `transactions_debit_credit` (Journal, Contra)  
- Stock: `lib/core/vouchers/stock/*` + `transactions_stock` (GT, MI, RQ, SR)

### Sprint E — Organization hard cases & access

| # | Work | Status |
|---|------|--------|
| E1 | CompanyProfile (logo out-of-band; list+edit) | `[x]` `organization_company` |
| E2 | ~~VoucherSeries~~ shipped (company id still plain int) | `[x]` |
| E3 | UserCredentials + role **permissions** matrix UI | `[x]` users + `/roles/:id/permissions` |
| E4 | Real permission read when BE-001 lands | `[x]` already `MatrixPermissionService` |

**Backend adds (Sprint E):** company update snake→Pascal map; `GET /organization/roles/:roleId/permissions`.

**Organization completion (post-E):** ProjectMaster; CurrencyRate list (`GET /rates/history` + `GET /rates/:id`); ConfigSetting edit-by-key; AuditLog list; ErrorReporting list+create. ExtraValues still deferred.

### Sprint F — HR depth (can parallel after A)

| # | Work | Status |
|---|------|--------|
| F1 | **EmployeeDetails** (Core + Bank + Salary tabs; dept/designation/contact FKs) | `[x]` `employee_employee` |
| F2 | **LeavePolicy** list/create (no PUT/DELETE/GET-by-id — list scan for view) | `[x]` |
| F3 | **LeaveRequest** list/create + approve/reject/cancel detail | `[x]` |
| F4 | **ShiftMaster** list/create | `[x]` |
| F5 | Document expiries / nested documents UI | `[ ]` |
| F6 | Attendance log + roster | `[ ]` |
| F7 | Shift assignment + payslip | `[ ]` |
| F8 | Leave allocation (per-employee list + create; BE-009) | `[x]` |

EmployeeDetails → leave policy/request → shifts shipped. Documents, attendance, payslip remain.

### Sprint G — Desk, reports, polish

| # | Work |
|---|------|
| G1 | Wire desk to `/reports/dashboard` + `/reports/alerts` |
| G2 | `ReportDefinition` + `ReportViewer` + CSV |
| G3 | Command palette over ManifestRegistry + voucher routes |
| G4 | Settings, RTL QA matrix, goldens, `architecture.md` |

### Explicitly later

| Item | When |
|------|------|
| Offline/sync + CR-001–008 | After online product ships value |
| Commercial charts/PDF kits | Never (plan forbids); print + CSV first |

---

## 4.1 Sprint A — design notes (ready to implement)

> Next engineering work when implementation starts. Do **not** invent GL or voucher UI here.

### A0. EMR unlocks (do first if AccountGroup is in scope)

| Task | Detail |
|------|--------|
| `FieldType.selfFk` | Same as `fk` for storage (parent id), but search/display is limited to same entity type; optional “no parent” clear |
| Tree picker widget | Reuse `FkLookupField` shape if possible; list flattens with indent from `parent_group_id` / `parent_dept_id` until a real tree control is needed |
| Manifest flag | Optional `treeParentField` on `EntityManifest` for future tree list mode — **only if** list UX needs it in Sprint A; otherwise form-only selfFk is enough |
| Tests | `field_renderer_test` + one AccountGroup mapper test |

**Workaround if selfFk slips:** ship LedgerMaster with `account_group_id` as `FieldType.fk` against AccountGroup **list**, and register AccountGroup as a **flat** master first (parent as optional int or deferred parent field). Prefer real selfFk if group hierarchy matters for UAE chart-of-accounts UX.

### A1. AccountGroup package

| Item | Value |
|------|--------|
| Path | `/accounts/groups` |
| RBAC | `Accounts` (coarse — entire accounts domain) |
| Soft delete | **Hard** (no `is_active` per inventory) |
| Fields (min) | `group_code`, `Group_Name`, `parent_group_id` (selfFk), system flag read-only if present |
| Package | `lib/features/accounts_account_group/` (or `accounts_group/`) — keep `accounts_` prefix for domain sorting |
| Menu | Under Accounts section: “Account group” → `/accounts/groups` |

### A2. LedgerMaster package (core form first)

| Item | Value |
|------|--------|
| Path | `/accounts/ledgers` |
| RBAC | `Accounts` |
| Soft delete | `is_active` |
| List columns | code, name, type, active (opening balance optional) |
| Form phase 1 | `ledger_code`, `Ledger_Name`, `Ledger_Type` (text or later enum), `account_group_id` (fk), `currency_code`, `is_active`, `Opening_Balance` as **Decimal** (DTO: string) |
| Form phase 2 (same package or tabs) | bank / credit / tax via nested GET/PUT under `/ledgers/:id/{bank,credit,tax}` — **not** separate menu entities |
| contact_id | Optional `FieldType.fk` → AddressBook repository (cross-module — same pattern as Designation) |
| Package | `lib/features/accounts_ledger/` |
| Menu | “Ledger” → `/accounts/ledgers` |

**Decimal rule:** DTO keeps wire string/float as backend sends; mapper → `package:decimal` `Decimal`. Never `double` in domain.

### A3. Cross-module FK convention (document + apply)

Already proven in Designation:

```dart
// In consuming manifest (module-level lazy repo):
final _ledgerRepository = createLedgerRepository(getIt<DioClient>());
// FormFieldSpec.fkSearch / fkDisplayOf / fkResolveById use that repo.
```

Rules to add to `manifest-spec.md` when implementing:

1. FK target package exposes `createXRepository(DioClient)`.
2. Consumer manifest owns the lazy repo singleton (not the form page).
3. No imports of another feature’s **presentation** layer.
4. Cross-domain RBAC: gate actions with **this** entity’s `rbacModule` (`Accounts`), not the target’s.

### A4. Shell wiring checklist

- [x] `menu_model.dart` — Account group + Ledger items (`requiredModule: 'Accounts'`)
- [x] `app_router.dart` — list + `/new` + `/:id` for each
- [x] Mapper tests under `test/features/accounts_*`
- [x] Leave `/accounts` hub as placeholder or make it a simple links page

### A5. Explicit non-goals for Sprint A

- Billwise, cheques, aging UI  
- ~~InventoryItem~~ → moved to Sprint B (shipped core)  
- Any voucher / DocumentSurface  
- Changing fail-open permissions  
- Offline  

### Done-when (Sprint A)

- [x] User can create AccountGroup (flat) and Ledger online against a running backend.  
- [x] Designation-style FK works for `account_group_id` (+ optional `contact_id`).  
- [x] Mapper tests green (`test/features/accounts_*`).  
- [x] STATUS matrices for AccountGroup + LedgerMaster flipped to `[x]` (extensions still open).  
- [x] Optional parent on AccountGroup (`selfFk`).  
- [x] Ledger bank/credit/tax tabs (nested create/update payload).

### Sprint B notes (InventoryItem)

| Decision | Choice |
|----------|--------|
| Package | `lib/features/inventory_item/` |
| Path | `/inventory/item` · menu **Item** · RBAC `Inventory` |
| Soft delete | `is_active` (not hard delete) |
| FKs same-module | UOM, Brand, Category, TaxCategory |
| FKs cross-module | 4× Ledger (`sales_gl_ledger_id`, purchase / sales-return / purchase-return) |
| Deferred | `inventory_group_id` (needs InventoryGroup + selfFk); legacy `Group_Id` → `"0"` on write |
| Money | `Price` / `base_price` / `standard_cost` / rates as **Decimal** in domain; DTO wire numbers |

### Done-when (Sprint B core)

- [x] User can list/create/edit InventoryItem online against a running backend.  
- [x] Cross-module Ledger FKs work from the item form.  
- [x] Mapper tests green (`test/features/inventory_item/`).  
- [x] STATUS InventoryItem → `[x]` (group still deferred).  
- [x] SKU + Batch masters (FK → Item).  
- [x] InventoryGroup + selfFk parent + item `inventory_group_id`.

---

## 5. How to update this file

When you ship or defer work:

1. Flip the mark in the domain matrix (`[ ]` → `[x]` / `[!]`).  
2. If deferred, add a row to [`manifest-exceptions.md`](./manifest-exceptions.md) (do not fork Surfaces).  
3. Bump **Last updated** at the top.  
4. Adjust the scorecard counts if a whole domain moves.  
5. Prefer this file for “what’s left?”; keep [`BUILD_TASKS_V2.md`](./BUILD_TASKS_V2.md) for wave narrative (its checkboxes may lag).

### Count helpers (masters only, approximate)

| Domain | Done | Deferred/blocked | Not started | Partial hubs |
|--------|------|------------------|-------------|--------------|
| Organization | 13 | 1 (extras) | 0 | 1 |
| Accounts | 2 | 0 | ~6 (extensions + billwise/cheque) | 1 |
| Inventory | 9 | ~11 | ~2 stock views | 1 |
| Employee | 7 | 0 | ~5 | 1 |
| Vouchers | 0 | 0 | ~17 + lifecycle | 1 |

---

## 6. Related docs

| Doc | Role |
|-----|------|
| [`feature-inventory.md`](./feature-inventory.md) | Full backend entity + endpoint map |
| [`feature-contract.md`](./feature-contract.md) | What a feature must supply |
| [`manifest-spec.md`](./manifest-spec.md) | 7-file master recipe |
| [`manifest-exceptions.md`](./manifest-exceptions.md) | Why an entity is not registered yet |
| [`api-contract.md`](./api-contract.md) | Wire shapes |
| [`backend-suggestions.md`](./backend-suggestions.md) | Backend gaps (BE-xxx) |
| [`offline-sync-readiness.md`](./offline-sync-readiness.md) | Parked offline track |
| [`SESSION_CONTEXT_EXPORT.md`](./SESSION_CONTEXT_EXPORT.md) | Architectural decisions snapshot |
| [`BUILD_TASKS_V2.md`](./BUILD_TASKS_V2.md) | Wave plan (EMR-driven) |
| [`UI_DESIGN_PLAN.md`](./UI_DESIGN_PLAN.md) | Visual / UX direction |
