# algoERP Frontend — Online-First Execution Plan

> **Superseded for execution by [`docs/BUILD_TASKS_V2.md`](./BUILD_TASKS_V2.md)** (manifest-driven plan, 2026-07-11).  
> Keep this file for historical context. Doctrine **R1–R7** and Wave 0 contracts still apply; v2 changes the *scale strategy* (declare manifests/blueprints + Surfaces instead of mass-stamping feature packages). Track A half-baked status is audited in v2 §1.2.

> **Architecture (2026-07-11): ONLINE-ONLY, INTERFACE-DRIVEN.**
> Repositories call the backend directly via Dio and return `Either<Failure, T>`.
> No local DB, no sync engine, no outbox — but **every data boundary is an interface**,
> so an offline/caching layer can be dropped in later without rewriting a single feature.
> The old drift/offline code (`lib/core/database/**`, sync deps in `pubspec.yaml`) is
> **PARKED** (kept, unused), not deleted. Thin reference-data caching is a deliberate
> *later* step, not part of this scope.

Legend: `[x]` done · `[~]` in progress · `[ ]` todo · `∥` parallel-safe group.

---

## 1. Engineering doctrine — the reuse rules every task obeys

These are not style preferences; they are what make 86 entities buildable by a small
number of generic components and what make the tracks below independent.

| # | Rule | Why it wins |
|---|------|-------------|
| **R1** | **Program to interfaces.** Every feature depends on `Repository<E, ID>`, never on a concrete HTTP class. | Offline/caching later = new implementation of the same interface. Zero feature edits. Enables parallel tracks. |
| **R2** | **One generic where you'd write forty.** `CrudBloc<E, F>`, `RemoteRepository<E, ID>`, `RemoteDataSource<E>` are written once. | A new master entity ships ~4 thin files (DTO, mapper, path, fromJson) — no new bloc/repo logic. |
| **R3** | **Sealed states, exhaustive UI.** `CrudState` = `initial \| loading \| loaded \| error`; `Failure` is sealed. | The compiler forces every screen to handle loading/empty/error. No "forgot the error branch" bugs. |
| **R4** | **Compose with mixins, don't inherit deep.** `PaginationMixin`, `SearchDebounceMixin`, `RbacMixin`, `FormMixin`. | Behaviors combine à la carte; no fragile base-class towers. |
| **R5** | **Contract-first → parallel work.** Freeze the interfaces (Wave 0) before implementations. | Three teams/agents build A, B, C simultaneously against frozen seams, then merge cleanly. |
| **R6** | **Single source of truth for the API.** `docs/api-contract.md` → typed `freezed` DTOs → domain entities via mappers. | The wire shape lives in exactly one place; drift between backend and UI is caught at the mapper. |
| **R7** | **Decimal for all money/qty, RBAC-by-default, adaptive-by-default.** No `double`; every action gated by `can(module, action)`; every screen uses adaptive layout primitives. | Correctness (GL math), security, and multi-platform are structural, not bolted on. |

**The teaching thread:** the two hardest things in an ERP frontend — *scale* (86 entities)
and *change* (online today, offline tomorrow) — are both solved by the same move:
**put a generic behind an interface.** Everything below is an application of that move.

---

## 2. Dependency map — what is unblocked right now

```
Step 0–4  ✅ DONE  (contract, scaffold, theme, responsive+nav, network+error)
   │
   ▼
Wave 0  Contracts & Seams   ← tiny, sequential, unlocks all parallelism
   │
   ├───────────────┬────────────────┐
   ▼               ▼                ▼
Track A          Track B          Track C          ← Wave 1, fully parallel
Reuse Keystone   Identity/Access  Widget Library
(ex-Step 7)      (ex-Step 8)      (ex-Step 9)
   └───────────────┴────────────────┘
                   ▼
Wave 2  Gold Template A (Brand)   ← integration point (A+B+C)
                   ▼
Wave 3  Mass replication          ← per-module / per-family, parallel
                   ▼
Wave 4  Assembly, reports, polish, QA, review
```

Steps 0–4 are complete, so **Wave 0 can start immediately.**

---

## 3. Wave 0 — Contracts & Seams  `[x]` ✅ DONE

Small, mostly interfaces + sealed types, **no business logic**. This is the keystone: once
frozen, Tracks A/B/C never block each other. Everything here lives in `lib/core/`.

- [x] `usecase/usecase.dart` — `abstract class UseCase<Out, In>` + `NoParams` (R2)
- [x] `domain/page_query.dart` — value object: `page, limit, search?, filters, sort?` + `SortSpec` (the one query shape every list uses)
- [x] `domain/repository.dart` — **`abstract interface class Repository<E, ID>`**: `list(PageQuery) → Result<Paginated<E>>`, `getById(ID)`, `create(E)`, `update(ID, E)`, `delete(ID)` (R1)
- [x] `data/remote_data_source.dart` — `abstract interface class RemoteDataSource` (raw `JsonMap` in/out over a resource path) (R1)
- [x] `data/mapper.dart` — `abstract interface class Mapper<D, E>` (`toEntity` / `toDto`) (R6)
- [x] `bloc/crud_contract.dart` — sealed `CrudState<E>` (initial/loading/loaded(items,meta,flags)/error) + `CrudEvent<E, F>` (R3)
- [x] `auth/permission_contract.dart` — `enum PermissionAction`, `PermissionService`, `RbacMixin` (R1, R7)
- [x] `widgets/view_state.dart` — sealed `ViewState<T>` (loading/empty/data/error), **bloc-decoupled** (R3)
- [x] `docs/feature-contract.md` — the fill-in-the-blanks recipe + locked conventions (R5)

**Done-when:** ✅ all interfaces compile clean (`flutter analyze` — no issues); 20 tests pass;
`feature-contract.md` is concrete enough that Tracks A/B/C can proceed independently.
Parked offline code excluded from analysis in `analysis_options.yaml`.

---

## 4. Wave 1 — Three mutually-exclusive parallel tracks

> Each track depends **only on Wave 0**, not on the other tracks. They can run fully in
> parallel and merge without conflict because they touch disjoint folders and share only
> the frozen contracts.

### ∥ Track A — Reuse Keystone (data + bloc engine)  `[ ]`
Folder ownership: `lib/core/data/`, `lib/core/bloc/`, `lib/core/usecase/`, `lib/core/utils/extensions/`

- [ ] `data/remote_data_source_base.dart` — Dio-backed generic `RemoteDataSource<E>` (list w/ page&limit&search, get, create, update, delete against an injected resource path). **Written once.** (R2)
- [ ] `data/remote_repository.dart` — `RemoteRepository<E, ID>` implements `Repository<E, ID>` via a `RemoteDataSource` + `Mapper`, wrapping every call in `safeCall` → `Either<Failure, T>` (R1, R2)
- [ ] `bloc/crud_bloc.dart` — generic `CrudBloc<E, F>`: load/loadMore/refresh/create/update/delete/search/filter → server pagination; `with PaginationMixin, SearchDebounceMixin` (R2, R4)
- [ ] `bloc/detail_bloc.dart` — `DetailBloc<E>` (load one / refresh / delete)
- [ ] `bloc/form_mixin.dart` — validation + maps `Failure.validation` field errors onto form fields (R3, R4)
- [ ] `bloc/mixins/{pagination,search_debounce}.dart`
- [ ] `utils/extensions/*` — `Either→CrudState`, `Decimal`/date formatting, `context.tokens/.l10n/.breakpoint` (R7)
- [ ] tests: `CrudBloc` via a **fake `Repository`** (load/paginate/create/delete/error) — proves the generic without any real entity

**Reuse mandate:** a feature must add **zero** bloc or repository *logic* — only wiring.

### ∥ Track B — Identity & Access  `[ ]`
Folder ownership: `lib/features/auth/`, `lib/core/auth/` (impl side of the Wave 0 contract)

- [ ] `features/auth/` domain+data+presentation: login (`POST /auth/login`), refresh, `GET /auth/me`, change-password, logout
- [ ] `AuthBloc` — `authenticated(user, permissions, companyId, branchId)` / `unauthenticated`
- [ ] `core/auth/permission_service_impl.dart` — implements Wave 0 `PermissionService` from the role matrix
- [ ] `core/auth/permission_gate.dart` — widget that hides/disables children per `can(module, action)`
- [ ] `go_router` guards — unauthenticated→`/login`, missing-permission→403 (fills the redirect seam left in Step 3)
- [ ] adaptive **login page** (uses Wave-0 `ViewState` + existing tokens; polish deferred to Wave 4) + multi-company/branch select
- [ ] tests: auth flows + guard redirects

**Parallel-safe** because it consumes only the RBAC *interface* and the (done) network layer.

### ∥ Track C — Reusable Widget Library  `[ ]`
Folder ownership: `lib/core/widgets/`, `docs/widget-catalog.md`, gallery route

- [ ] `docs/widget-catalog.md` — enumerate every widget across both archetypes (props, responsive, RTL) (R6)
- **C1 (token-only, depends on nothing but theme — start immediately):** `∥`
  - [ ] buttons, typed fields (text/number/**decimal**/date/currency/switch/dropdown-enum) (R7)
  - [ ] status chips, confirm dialogs, snackbars, filter bar, page scaffold + breadcrumbs, tabs/section cards, file/image picker, stat/KPI card, chart wrappers
  - [ ] `async_state_view.dart` — renders Wave-0 `ViewState<T>`: skeleton loading, branded empty+CTA, friendly error+retry (R3)
- **C2 (contract-coupled — builds against Wave-0 `Repository`/`CrudState`, demoed with fakes):** `∥`
  - [ ] **async FK-lookup field** — searchable, paginated remote lookup against the `Repository` interface (real repo drops in at Wave 2)
  - [ ] **adaptive data-table ↔ card-list** — renders `CrudState.loaded`, sort/select/paginate
  - [ ] **dynamic line-item grid** — add/remove/reorder rows + `decimal` running totals (for vouchers, Wave 3)
- [ ] gallery route — every widget in light/dark × LTR/RTL

**The seam that makes C2 parallel-safe:** the FK-lookup and data-table talk to the *same*
`Repository<E, ID>` interface Track A implements. Built against a fake now, wired to the
real repo at merge — no rework. (R1, R5)

---

## 5. Wave 2 — Gold Template A: Brand (integration point)  `[ ]`

First place A + B + C meet. One entity, built end-to-end, becomes the mechanical recipe.

- [ ] `features/inventory_brand/` full slice: domain (entity, `Repository` binding, usecases) → data (freezed DTO+fromJson, mapper, resource path) → presentation (`CrudBloc` wiring, adaptive list w/ RBAC-gated actions, detail, create/edit form)
- [ ] ONE richer master to prove hard cases: **Designation** (FK→Department via the FK-lookup field) **or** **AccountGroup** (self-referential tree + parent selector excluding self/descendants)
- [ ] `docs/templates/master-crud-template.md` — fill-in-the-blanks recipe: exact file list + "what changes per entity" (path, fields, enums, FKs, RBAC module)
- [ ] bloc + widget tests

**Done-when:** Brand lists/creates/edits/deletes online on web+desktop; the template doc is
mechanical enough that the next 39 are pure stamping.

---

## 6. Wave 3 — Mass replication (heavily parallel)  `[ ]`

### ∥ Masters — one parallel unit **per module** (mutually exclusive)
Each module reads its field/enum/FK/endpoint/RBAC facts from `docs/feature-inventory.md`
and stamps the Wave-2 template. Different folders → conflict-free parallel.
- [ ] `∥` Organization (11): CompanyProfile, FinancialYear, Branch, Currency, CurrencyRate, VoucherSeries, AddressBook, UserRole, UserCredentials, Permissions, ProjectMaster
- [ ] `∥` Accounts masters (AccountGroup, LedgerMaster + 1:1 tabs, BillwiseRecord, ChequeDetails)
- [ ] `∥` Inventory remaining (~17)
- [ ] `∥` Employee masters (Department, Designation, EmployeeDetails + 1:1 tabs, …)
- [ ] `∥` Transactions ancillary (TermsAndConditions, TransportationDetails)
- **Rule:** any entity that doesn't fit the template → STOP, emit a note/CR, don't improvise.

### Wave 3b — Gold Template B: Sales Invoice voucher  `[ ]`
Sequential (most complex screen; copied 17×). Depends on masters (FK lookups).
- [ ] header form (customer FK-lookup w/ live outstanding/credit-limit) + dynamic line grid (auto price/tax, `decimal` totals) + save-draft vs **post directly online**
- [ ] voucher list (date/status/customer filters) + read-only view + GL preview + print/PDF
- [ ] lifecycle bloc: buttons per `voucher_status` (edit-if-Draft; approve/cancel/reject per RBAC) + reason capture
- [ ] `docs/templates/voucher-document-template.md` + `voucher-type-matrix.md`

### ∥ Vouchers — one parallel unit **per family**
- [ ] `∥` Pre-sales (Quotation, SalesOrder, PurchaseOrder)
- [ ] `∥` Sales (DeliveryNote, CreditNote, DebitNote)
- [ ] `∥` Purchase (PurchaseInvoice, ReceiptNote)
- [ ] `∥` Financial (Payment, Receipt, Journal, Contra — debit/credit line variant)
- [ ] `∥` Inventory (GodownTransfer from/to, MaterialIn, StockRequest, Requirement)
- [ ] `∥` Payroll (Payslip)

---

## 7. Wave 4 — Assembly & quality  `[ ]`

- [ ] Step 14 — wire full RBAC-gated menu into the shell; `features/dashboard/` (KPI cards, alerts, global search w/ typeahead); settings (theme, en/ar, company/branch, logout)
- [ ] Step 15 — `∥` reports: build `ReportViewer` framework + `ReportDefinition` once, then **stamp each report config in parallel** (register, stock, VAT, trial-balance, P&L, balance-sheet, day-book, ledger-statement, outstanding/aging, overtime/attendance) + CSV/PDF/Excel export
- [ ] Step 16 — `∥` polish: finalize motion + apply `AsyncStateView` everywhere (skeleton/empty/error), RTL-correct transitions, goldens
- [ ] Step 17 — responsive/multi-platform QA matrix (breakpoints × platforms × LTR/RTL × light/dark) → `docs/qa/responsive-qa.md` + fixes + breakpoint goldens
- [ ] Step 18 — consolidate CRs (offline ones stay deferred), completeness audit vs `feature-inventory.md`, `docs/STATUS.md` + `docs/architecture.md`

---

## 8. Definition of Done (every wave & task)
- [ ] `flutter analyze` clean (very_good_analysis, 80-col)
- [ ] `flutter test` green (bloc_test + goldens where applicable)
- [ ] No hardcoded colors/sizes (tokens only); no `double` for money/qty; every action RBAC-gated
- [ ] No new primitives inside a feature — only shared widgets/blocs/repos (R2)
- [ ] Wave's own Done-when met

---

## 9. Parked (do not delete)
- `lib/core/database/**` (sync_status, sync_columns, outbox) — reintroduce with the offline phase
- `pubspec.yaml`: drift, drift_flutter, sqlite3_flutter_libs, workmanager — unused for now
- `docs/change-requests/CR-001…CR-008` — offline-sync CRs, deferred
