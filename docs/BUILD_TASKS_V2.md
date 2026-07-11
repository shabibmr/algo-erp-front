# algoERP Frontend — Manifest-Driven Execution Plan (v2)

> **Status update — 2026-07-11 (post vertical-slice):** rather than building the full EMR
> (A3) before proving it, we built a deliberately narrow **vertical slice**: the manifest
> model (§7 A3.1, minimal `FieldType`), `MasterListSurface` only (§7 A3.3, list Surface
> only), and Brand's list binding (§8 A4, list only — no hard-case entity, no recipe doc
> yet). This is intentionally short of A3/A4's full done-when criteria — see the inline
> `[~]` notes in those sections. **Decision point:** now that `/inventory/brand` renders
> real backend data through `MasterListSurface`, decide with the user whether to extend
> EMR (detail/form Surfaces, more masters) or fall back to v1 hand-written features before
> building anything further. See `docs/SESSION_CONTEXT_EXPORT.md` §4 and §8 for the full
> reasoning behind this checkpoint.

> **Curated successor to** `docs/BUILD_TASKS.md` **and** `PROMPT_EXECUTION_PLAN.md`.
> Date: 2026-07-11 · Architecture: **ONLINE-ONLY, INTERFACE-DRIVEN, MANIFEST-RENDERED**.
>
> Offline/sync (`lib/core/database/**`, drift, outbox, CRs 001–008) stays **PARKED**.
> Repositories still speak `Repository<E, ID>` so offline can drop in later with zero feature rewrites.

Legend: `[x]` done · `[~]` in progress / half-baked · `[ ]` todo · `∥` parallel-safe · `★` unique differentiator

---

## 0. Why this plan exists

The original plan ships ~40 master slices and ~18 voucher slices by **stamping nearly identical feature packages**. That works, but it is:

| Problem | Cost |
|---------|------|
| Thousands of near-duplicate files | Drift, review fatigue, inconsistent UX |
| Flash/mass-gen dependency | Quality cliffs when an entity doesn’t fit the template |
| “Unique” only as volume of CRUD | Looks like every other ERP shell |
| Offline-first assumed early | Heavy, blocked on backend CRs we deferred |

**v2 keeps what already works** (Clean Architecture seams, generic data/bloc engine, adaptive shell, tokens, online Dio path) and replaces mass stamping with a **manifest runtime**: each entity is a **typed declaration**, not a forked feature tree. The UI is rendered by shared **Surfaces**. That is the differentiator — and it uses **only free / first-party stack** already in `pubspec.yaml` (or pure Dart we own). No SaaS UI builders, no paid component kits, no commercial code generators.

---

## 1. Status audit (ground truth — do not re-discover)

### 1.1 Done (Steps 0–4 + Wave 0)

| Area | Evidence |
|------|----------|
| Discovery docs | `docs/feature-inventory.md`, `api-contract.md`, offline CRs (parked), `backend-suggestions.md` |
| Scaffold / flavors / DI | `lib/main_*.dart`, `get_it` + `injectable`, `very_good_analysis` |
| Design system | `AppTokens`, light/dark, motion, theme preview, en+ar ARB |
| Adaptive shell | breakpoints, `AppShell`, data-driven `AppMenu`, go_router shell |
| Network | Dio + auth/tenant/requestId interceptors, `ApiResponse`, `Paginated`, sealed `Failure`, `safeCall` |
| Wave 0 contracts | `Repository`, `RemoteDataSource`, `Mapper`, `PageQuery`, `CrudState`/`CrudEvent`, `PermissionService`, `ViewState`, `feature-contract.md` |

### 1.2 Track A — Reuse Keystone  `[x]` DONE (as v1's Wave 0/Track A scope — NOT v2's expanded A0)

**Present, compiling, tested** under `lib/core/{data,bloc,utils}`, all green
(`flutter analyze`/`flutter test` — 62/62 passing as of 2026-07-11):

| Artifact | State | Gap vs this doc's original A0 wishlist |
|----------|-------|--------------------------|
| `RemoteDataSourceBase` | Implemented, used by Brand | No `RepoBinding` DI helper (A0.2) — deferred, see A3.2 |
| `RemoteRepository` | Implemented, 8 tests | Same — no generic DI factory yet |
| `CrudBloc<E,ID,F>` | Implemented, 8 tests green | Pagination/search logic is **inlined** + `debounceRestartable` transformer, not separate mixins — accepted design, not revisited |
| `DetailBloc` | Implemented | Still no tests (no detail Surface consumes it yet) |
| `FormMixin` | Implemented, used by Track B's `AuthBloc` | No submit lifecycle/dirty tracking beyond field-error mapping (A0.3) — not yet needed |
| `ClientQuery` adapter (A0.4) | **Not built** | Deferred — BE-002/003/004 workaround not yet needed by Brand's list |
| Idempotency-Key interceptor (A0.5) | **Not built** | Deferred |
| `features/**` | Brand only (`inventory_brand/`) | The vertical slice's one binding |

v2's *expanded* A0 checklist (ClientQuery, idempotency shield, RepoBinding
helper, documenting deviations) remains open — it was consciously deferred by
the vertical-slice plan, not forgotten. Revisit at the next EMR-extension
decision point.

### 1.3 Status of the rest

- **Track B — Identity & Access:** `[x]` DONE. Full auth stack
  (`lib/features/auth/**`), `FailOpenPermissionService` (BE-001), router
  guards (`/login`, `/403`, `appRouterRedirect`), 12 tests.
- **Track C — Widget library:** `[x]` DONE. `lib/core/widgets/**` (fields,
  chips, dialogs, filter bar, FK lookup, adaptive list, line-item grid,
  `AsyncStateView`), `docs/widget-catalog.md`, gallery route, 14 tests.
- **EMR vertical slice (A3/A4, partial):** `[~]` see §7/§8 below.
- **Not started:** Mass masters (A5) · Voucher blueprints/DocumentSurface (A6/A7)
  · Dashboard/reports/palette (A8) · Polish/QA (A9).

### 1.4 Backend frictions that shape the plan (from `backend-suggestions.md`)

| ID | Impact on frontend |
|----|--------------------|
| BE-001 no permission matrix read | Fail-open RBAC until endpoint exists |
| BE-002/003/004 no search/filter/sort | Ship a **client query adapter** over loaded pages + still forward params |
| BE-005 no idempotency keys | Client generates keys; don’t auto-retry mutating verbs |
| BE-008 no lightweight lookup DTOs | FK field uses full list endpoint + projection in UI |

---

## 2. Unique product thesis (license-free)

### ★ Entity Manifest Runtime (EMR)

> **The schema is the feature.**  
> Masters are not 40 folders of boilerplate. They are **manifest entries** consumed by one **MasterSurface**.  
> Vouchers are **blueprints** consumed by one **DocumentSurface**.

```
┌─────────────────────────────────────────────────────────────┐
│  EntityManifest / VoucherBlueprint  (typed Dart, freezed)   │
│  path · rbacModule · fields · columns · fks · validators    │
└───────────────────────────┬─────────────────────────────────┘
                            │
         ┌──────────────────┼──────────────────┐
         ▼                  ▼                  ▼
  RepoFactory          CrudBloc/Detail     MasterSurface
  (RemoteRepository    (already built)     FormSurface
   + path + codec)                         DocumentSurface
         │                  │                  │
         └──────────────────┴──────────────────┘
                            │
                    PermissionGate + go_router
```

**Why this is unique for a UAE SME ERP (and free):**

1. **Declarative masters** — adding Brand/Category/UOM is a manifest + DTO/mapper (~tens of lines), not a cloned feature package.
2. **Surfaces, not screens** — one adaptive list/detail/form engine; density, RTL, and keyboard paths stay consistent by construction.
3. **★ Command palette** (`Ctrl/Cmd+K`) — jump to any manifest route, action, or report by fuzzy name (desktop-first power UX rare in Flutter ERPs).
4. **★ Decimal Line Engine** — pure-Dart running totals / tax / discount for vouchers; never `double`; unit-tested as a domain kernel.
5. **★ Client Query Layer** — until BE-002–004 land, search/sort/filter run through a free, testable adapter on the client without lying about server capabilities.
6. **★ Idempotent write shield** — UUID `Idempotency-Key` header on POST (harmless if ignored; correct when BE-005 lands).
7. **OpenAPI-aligned DTOs** — generate or hand-map from backend OpenAPI; single wire truth (no paid API client).
8. **Parked offline stays parked** — interface-first so a later drift phase is an implementation swap, not a rewrite.

### Stack boundary (non-negotiable)

| Allowed | Forbidden for this plan |
|---------|-------------------------|
| Flutter/Dart SDK, Material 3 | Paid UI kits (Syncfusion commercial, Telerik, …) |
| Packages already in `pubspec` (bloc, dio, freezed, fpdart, go_router, decimal, …) | SaaS low-code / FlutterFlow export |
| Pure Dart we write under `lib/core/**` | Paid design systems / icon packs with license fees |
| Free OSS only if needed (e.g. `collection`, `fuzzy` pure Dart) | Embedding commercial chart/PDF engines that require keys |
| Browser print / HTML→PDF where possible | Closed source report servers |

Charts: prefer **CustomPainter / free chart primitives** or simple sparkline widgets we own.  
PDF: start with **browser print layouts** + optional pure-Dart table export (CSV always free).

### What we deliberately keep from v1

- R1–R7 reuse doctrine (`BUILD_TASKS.md` §1)
- Online-first `RemoteRepository` + `Either<Failure,T>`
- Adaptive shell + tokens + RBAC interfaces
- Two archetypes: **Master** vs **Voucher document**
- Gold-then-scale — but scale = **register manifests**, not clone packages

---

## 3. Dependency map

```
Done: Steps 0–4 + Wave 0 contracts
              │
              ▼
   Wave A0  Finish Track A (stabilize half-baked engine)     ← sequential, small
              │
   ┌──────────┼──────────────┐
   ▼          ▼              ▼
Wave A1    Wave A2        Wave A3          ← parallel after A0
Auth/RBAC  Widget atoms   ★ EMR core
 (B)       + gallery      (manifest +
            (C1)           surfaces)
   └──────────┼──────────────┘
              ▼
   Wave A4  Gold path: Brand (manifest) + Designation (FK proof)
              │
   ┌──────────┼──────────────┐
   ▼          ▼              ▼
Wave A5    Wave A6        Wave A7
Register   Document       Register
all        Surface +      voucher
masters    Sales Invoice  blueprints
   └──────────┼──────────────┘
              ▼
   Wave A8  Shell assembly, dashboard, command palette, reports
              │
              ▼
   Wave A9  Polish, multi-platform QA, STATUS/architecture
```

---

## 4. Wave A0 — Stabilize Track A (half-baked → solid)  `[~]`

**Folder ownership:** `lib/core/data/`, `lib/core/bloc/`, `lib/core/utils/`, tests under `test/core/`

- [ ] **A0.1** Document intentional deviations in `docs/feature-contract.md`:
  - pagination helpers = `PaginationMeta` extensions (not a class mixin)
  - search debounce = `debounceRestartable` event transformer
  - `CrudBloc` is `CrudBloc<E, ID, F>` (three type params)
- [ ] **A0.2** `RepoBinding<E, ID>` (or `registerRemoteRepository`) — one DI helper that wires  
  `RemoteDataSourceBase(path) + decode/encode/idOf → RemoteRepository` so features never copy glue.
- [ ] **A0.3** Harden `FormMixin` → thin **`FormController` / `FormCubit` patterns**:
  - field error map from `Failure.validation` (already)
  - submit in-flight flag, general error, clear-on-edit
  - no per-entity form blocs
- [ ] **A0.4** **ClientQuery** adapter (`lib/core/data/client_query.dart`):
  - given `List<E>` + `PageQuery` + field accessors, apply search/sort/filter **in-memory**
  - optional wrap in repository decorator for entities without server search
  - unit tests for multi-field search + sort dir
- [ ] **A0.5** **Idempotency** interceptor or Dio option: attach `Idempotency-Key` (uuid) on POST; never auto-retry POST/PUT/DELETE (document in network layer)
- [ ] **A0.6** Tests: `RemoteRepository` (decode/encode + safeCall left/right), `DetailBloc`, `ClientQuery`, expand `CrudBloc` edge cases if missing
- [ ] **A0.7** Mark Track A complete in this file + leave parked DB excluded from analysis

**Done-when:** `flutter analyze` clean; all core tests green; DI helper usable from a one-file fake entity test.

---

## 5. Wave A1 — Identity & Access  `[ ]`  ∥ after A0

**Folders:** `lib/features/auth/`, `lib/core/auth/`

- [ ] Login / refresh / me / change-password / logout (existing API)
- [ ] Secure token storage (already stubbed: `token_storage.dart` — complete wiring)
- [ ] `AuthBloc`: `authenticated | unauthenticated | unknown`
- [ ] `PermissionService` impl — **fail-open** until BE-001; still call `can()` everywhere
- [ ] `PermissionGate` widget + go_router redirect (login / 403)
- [ ] Adaptive login + company/branch context (session claims / headers)
- [ ] Tests: auth flows, redirect matrix

**Done-when:** Real login against running backend; unauthenticated shell unreachable; gates compile into menu later.

---

## 6. Wave A2 — Widget atoms + gallery  `[ ]`  ∥ after A0

**Folders:** `lib/core/widgets/`, `docs/widget-catalog.md`

Build **token-only** primitives first (no paid Widgetbook — a simple `/gallery` route is enough).

- [ ] `docs/widget-catalog.md` — props, responsive, RTL for each widget
- [ ] Buttons, typed fields: text / number / **decimal** / date / currency / switch / enum dropdown
- [ ] Status chips, confirm dialog, snackbar host, filter bar, page scaffold + breadcrumbs
- [ ] Tabs / section cards, file/image picker (platform free APIs), KPI card
- [ ] `AsyncStateView` over Wave-0 `ViewState` (skeleton / empty+CTA / error+retry)
- [ ] Lightweight chart/sparkline wrappers we own (CustomPainter) — no commercial chart license
- [ ] Gallery: light/dark × LTR/RTL

**Contract-coupled widgets (need EMR interfaces — may land late A2 or early A3):**

- [ ] Async FK lookup (against `Repository` + fake)
- [ ] Adaptive data-table ↔ card-list bound to `CrudState`
- [ ] Dynamic line-item grid (decimal totals via Line Engine)

**Done-when:** Gallery route demos every atom; no hardcoded colors/sizes.

---

## 7. Wave A3 — ★ Entity Manifest Runtime (core differentiator)  `[~]` VERTICAL SLICE ONLY

**Folders:** `lib/core/manifest/`, `lib/core/surfaces/`, `docs/manifest-spec.md`

### A3.1 Manifest model (typed, freezed or hand-sealed)  `[~]`

- [x] `FieldType` — **minimal by design**: only `text`/`dateTime` exist
      (`lib/core/manifest/field_spec.dart`). The full set (int/decimal/bool/enum/
      fk/selfFk/json/binary) is deliberately not built — it grows from real
      pressure (next: `LedgerMaster` needs `decimal`+`fk`, `AccountGroup` needs
      `selfFk`), not speculation.
- [x] `FieldSpec<E>`: `key`, `label`, `type`, `required`, `cellValue` closure. No
      `wireKey`/l10n key/`readOnly`/`validators`/`visibleIn` yet — not needed
      until a form Surface exists.
- [ ] `FkSpec` — not built.
- [~] `EntityManifest<E>`: has `id`, `label`, `rbacModule`, `resourcePath`,
      `listColumns[]`, `searchFields[]`. Missing `idField`, `fields[]`,
      `formSections[]`, `deleteMode`, `treeParentField` — all deferred with
      the (nonexistent) form/detail Surfaces they'd serve.
- [ ] `ManifestRegistry` — not built. Only one manifest (`brandManifest`)
      exists as a top-level `final` constant; a registry is premature with one entry.

### A3.2 Binding layer  `[ ]` not built

- [ ] `EntityCodec<E>` generic interface — Brand instead uses a bespoke
      `BrandMapper`/`BrandDto` pair (Track A/B precedent: hand-written, no
      freezed). Revisit generalizing once a second manifest exists.
- [ ] `MasterBinding<E, ID>` / `RepoBinding` DI helper — not built. Brand's DI
      is three plain factory functions in `lib/features/inventory_brand/brand_di.dart`.
      **Intentionally not generalized yet** — see that file's doc comment.

### A3.3 Surfaces (generic UI)  `[~]`

- [x] `MasterListSurface<E>` (`lib/core/surfaces/master_list_surface.dart`) —
      adaptive table/cards (via Track C's `AdaptiveEntityList`), search (via
      `FilterBar` → `CrudSearchChanged`), infinite scroll (new: a
      `NotificationListener<ScrollNotification>` dispatching
      `CrudLoadMoreRequested`, since `AdaptiveEntityList` takes a plain list),
      RBAC-gated "New" action via `PermissionGate`. Tested:
      `test/core/surfaces/master_list_surface_test.dart`.
- [ ] `MasterDetailSurface` — not built.
- [ ] `MasterFormSurface` — not built.
- [ ] `FieldRenderer` switch — not built (list-only rendering is inlined in
      `MasterListSurface` via `FieldSpec.cellValue`; a real renderer switch
      is only needed once `FieldType` grows past `text`/`dateTime`).
- [ ] Route factory (`/m/:manifestId/...`) — not built. Brand is wired as a
      normal, individually-registered route (`/inventory/brand` in
      `app_router.dart`), not through a generic manifest-id route.

### A3.4 ★ Command palette  `[ ]` not built — deferred past the checkpoint

### A3.5 Spec & tests  `[~]`

- [ ] `docs/manifest-spec.md` — not written (one entity isn't enough to
      generalize a recipe from yet).
- [x] Widget test: `MasterListSurface` rendered against a fake tiny manifest +
      fake repo (loading/error/search-dispatch) — `test/core/surfaces/master_list_surface_test.dart`.
- [ ] Registry/field-visibility/ClientQuery tests — N/A, those components don't exist yet.

**Done-when (full A3, not yet met):** A fake "WidgetDemoEntity" works
end-to-end with **zero** feature-folder CRUD code beyond codec + manifest
registration. **Slice done-when (met):** Brand's list renders through
`MasterListSurface` against the real backend with zero list/table code of its
own beyond the manifest + DI factories.

---

## 8. Wave A4 — Gold path: Brand + hard-case master  `[~]` LIST ONLY

Prove EMR against real backend data.

- [x] **Brand** binding: hand-written DTO (not freezed, matches Track A/B
      precedent) + entity + mapper + manifest, path `/inventory/brand`,
      **hard delete** (verified: `brands` table has no `is_active` column),
      RBAC module `'Inventory'` (verified against `inventory.routes.ts` —
      **not** `'Brand'`; the backend gates the whole inventory module coarsely).
      Files: `lib/features/inventory_brand/{brand_manifest,brand_di}.dart`,
      `data/{brand_dto,brand_mapper}.dart`, `domain/brand.dart`.
- [x] Wire DI (plain factories, see A3.2 note) + menu item (`menu_model.dart`)
      + RBAC gate (`PermissionGate` in `MasterListSurface`).
- [x] **List** online, adaptive table/cards — verified via widget test against
      a fake repo (no live backend run yet in this session).
- [ ] Create / edit / delete — **not built**. No form/detail Surface exists
      (A3.3), so Brand has no way to create or mutate yet; list is read-only
      for now.
- [ ] **Hard case (Designation FK / AccountGroup self-FK tree)** — not
      attempted. Both need `FieldType.fk`/`selfFk`, which don't exist yet
      (A3.1) — correctly sequenced *after* this checkpoint, not before.
- [ ] `docs/templates/master-manifest-recipe.md` — not written (premature
      with one manifest).
- [x] Tests: `test/features/inventory_brand/brand_mapper_test.dart` (DTO/mapper
      round-trip, 5 cases) + the shared `MasterListSurface` test (A3.5) covers
      Brand's rendering path generically.

**Done-when (full A4, not yet met):** Brand is production-usable online
(create/edit/delete included); recipe is mechanical enough to register the
next master without inventing UI. **Slice done-when (met):** Brand's list is
demonstrably manifest-driven end to end — see `docs/SESSION_CONTEXT_EXPORT.md`.

---

## 9. Wave A5 — Register remaining masters (not clone them)  `[ ]`  heavily ∥

For each module, work is **DTO + mapper + codec + manifest + DI line**, not new pages.

| Parallel unit | Entities (from feature-inventory) |
|---------------|-----------------------------------|
| ∥ Organization | CompanyProfile, FinancialYear, Branch, Currency, CurrencyRate, VoucherSeries, AddressBook, UserRole, UserCredentials, Permissions, ProjectMaster (+ config/error as needed) |
| ∥ Accounts | AccountGroup (tree), LedgerMaster (+ 1:1 bank/credit/tax **tabs via form sections**), BillwiseRecord, ChequeDetails |
| ∥ Inventory | remaining ~17 masters |
| ∥ Employee | Department (tree), Designation, EmployeeDetails (+ tabs), docs, leave, attendance, shifts, … |
| ∥ Ancillary | TermsAndConditions, TransportationDetails |

**Rules:**

- [ ] No new list/form widgets inside a feature
- [ ] Entity doesn’t fit FieldSpec/Surface → **STOP** + note in `docs/change-requests/` or `docs/manifest-exceptions.md` — don’t fork Surface ad-hoc
- [ ] 1:1 extensions = extra `formSections` / tabs, same binding
- [ ] Hierarchical = `treeParentField` + shared tree picker widget

**Done-when:** Analyze clean; each registered master listable/editable online; coverage matrix vs `feature-inventory.md` updated.

---

## 10. Wave A6 — ★ Document Surface + Sales Invoice gold  `[ ]`

Vouchers are not manifests of flat fields alone — they are **blueprints**.

### A6.1 Decimal Line Engine (domain kernel)

- [ ] Pure Dart: line net, tax, discount, document totals — all `Decimal`
- [ ] Property tests / fixtures matching backend posting expectations where known
- [ ] Zero UI dependency

### A6.2 `VoucherBlueprint`

- [ ] party: customer | supplier | none | dual-ledger
- [ ] lineShape: itemQty | ledgerAmount | debitCredit
- [ ] flags: affectsGl, affectsStock, needsGodown, needsBatch
- [ ] lifecycle: which of draft/approve/cancel/reject apply
- [ ] endpoints: create, list, get, edit, approve, cancel, reject
- [ ] rbacModule

### A6.3 DocumentSurface

- [ ] Header form (FK party + live outstanding/credit when API allows)
- [ ] Dynamic line grid (A2 widget) bound to Line Engine
- [ ] Save draft vs post **online** (server authoritative numbering)
- [ ] List + filters (ClientQuery until BE-003)
- [ ] Read-only view + GL preview if API returns it
- [ ] Lifecycle buttons per status + reason capture + RBAC
- [ ] Print-friendly layout (browser print CSS / Flutter print)

### A6.4 Sales Invoice gold

- [ ] Full blueprint + binding for Sales Invoice
- [ ] `docs/templates/voucher-blueprint-recipe.md` + seed of `voucher-type-matrix.md`
- [ ] Tests: totals engine, lifecycle visibility, create happy path (mock repo)

**Done-when:** Create and post Sales Invoice online; totals stable; template ready for other types.

---

## 11. Wave A7 — Register voucher blueprints  `[ ]`  ∥ by family

| Family | Types |
|--------|-------|
| ∥ Pre-sales | Quotation, SalesOrder, PurchaseOrder |
| ∥ Sales | DeliveryNote, CreditNote, DebitNote |
| ∥ Purchase | PurchaseInvoice, ReceiptNote |
| ∥ Financial | Payment, Receipt, Journal, Contra (debit/credit line shape) |
| ∥ Inventory | GodownTransfer, MaterialIn, StockRequest, Requirement |
| ∥ Payroll | Payslip |

- [ ] Each type = blueprint row + DTOs/mappers + DI — **reuse DocumentSurface**
- [ ] Settlement allocation: abstract + CR if API missing (do not fake GL)
- [ ] Escalate matrix gaps; no silent improvisation

**Done-when:** Each type lists/creates/views; financial lines balance client-side; analyze clean.

---

## 12. Wave A8 — Assembly, command UX, dashboard, reports  `[ ]`

- [ ] Menu fully driven by **ManifestRegistry + voucher blueprints + RBAC**
- [ ] ★ Command palette wired to full registry
- [ ] Dashboard: KPI cards, alerts, global search typeahead (reports endpoints)
- [ ] Settings: theme, en/ar, company/branch, logout
- [ ] **Report framework** (declarative, free):
  - `ReportDefinition` (params, columns, endpoint, export flags)
  - `ReportViewer` surface (filter bar → adaptive table → **CSV export** first; PDF via print)
  - Stamp report defs in parallel (sales/purchase register, stock, VAT, TB, P&L, BS, day-book, ledger, aging, HR summaries)
- [ ] Missing backend reports → CR + placeholder definition

**Done-when:** Logged-in user navigates by menu **or** palette; dashboard live; reports export CSV.

---

## 13. Wave A9 — Polish, QA, handoff  `[ ]`

- [ ] Motion language applied; AsyncStateView everywhere
- [ ] RTL-correct transitions; skeleton/empty/error consistency
- [ ] Responsive matrix: breakpoints × web/desktop/mobile × LTR/RTL × light/dark → `docs/qa/responsive-qa.md`
- [ ] Goldens for surfaces (list/form/login/invoice) via existing `alchemist`
- [ ] Completeness audit vs `feature-inventory.md`
- [ ] `docs/STATUS.md` + `docs/architecture.md` (include EMR diagram)
- [ ] Confirm parked offline artifacts still unused and documented

**Done-when:** QA matrix closed or tracked; architecture doc reflects manifest-driven reality.

---

## 14. Definition of Done (every wave)

- [ ] `flutter analyze` clean (very_good_analysis, 80-col)
- [ ] `flutter test` green
- [ ] No hardcoded colors/sizes; no `double` for money/qty
- [ ] Every action RBAC-gated via `can(module, action)` even if fail-open
- [ ] No new per-entity list/form primitives — only manifests/blueprints + shared surfaces
- [ ] No paid/third-party licensed UI or report runtime introduced
- [ ] Wave-specific Done-when met

---

## 15. Explicit non-goals (this plan)

| Non-goal | Why |
|----------|-----|
| Offline-first sync engine | Parked; backend CRs incomplete; online ships value first |
| Commercial chart/PDF/grid suites | License cost; we own surfaces |
| Cloning 40 feature packages | Replaced by EMR |
| Building Widgetbook Cloud / paid catalogs | Local gallery route is enough |
| Guessing missing backend APIs | CR + adapter, never invent GL |

---

## 16. Mapping from old plan → v2

| Old (BUILD_TASKS / PROMPT plan) | v2 |
|---------------------------------|----|
| Track A engine | Wave A0 (finish half-baked) |
| Track B auth | Wave A1 |
| Track C widgets | Wave A2 |
| — | **Wave A3 EMR + command palette (new)** |
| Wave 2 Brand gold feature package | Wave A4 Brand **manifest** |
| Wave 3 mass stamp masters | Wave A5 **register** manifests |
| Wave 3b Sales Invoice package | Wave A6 DocumentSurface + blueprint |
| Wave 3 voucher stamp | Wave A7 register blueprints |
| Wave 4 shell/reports/polish | Waves A8–A9 (+ palette, free reports) |
| Steps 5–6 offline | Still parked |

---

## 17. Immediate next actions (start here)

1. **A0.1–A0.7** — stabilize Track A (this unblocks all parallel work).
2. Spin **A1 / A2 / A3** in parallel only after A0 Done-when.
3. Do **not** create `features/inventory_brand/**` full CRUD clones — wait for A3 surfaces, then A4 binding.
4. Keep editing this file’s checkboxes as the source of truth; leave `BUILD_TASKS.md` as historical online-first plan or mark it superseded at the top.

---

## 18. Supersession notice

When execution switches fully to v2, add at the top of `docs/BUILD_TASKS.md`:

```markdown
> **Superseded by `docs/BUILD_TASKS_V2.md` (manifest-driven plan).**
> Keep this file for historical context of Waves 0–1 doctrine (R1–R7 still apply).
```

Doctrine **R1–R7** remains binding. Only the **scale strategy** changes: from “stamp features” to “declare manifests / blueprints and render Surfaces.”
)
