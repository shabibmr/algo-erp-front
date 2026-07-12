# algoERP Frontend — Manifest-Driven Execution Plan (v2)

> **Living completion matrix:** [`docs/STATUS.md`](./STATUS.md) (updated 2026-07-12) — entity-by-entity
> checkboxes vs `feature-inventory.md`, scorecard, and recommended sprint build order. Prefer STATUS
> for “what’s done / what’s left”; this file remains the wave narrative and EMR doctrine.

> **Status update — 2026-07-12:** EMR extended past the Brand list slice. `MasterFormSurface`,
> expanded `FieldType` (incl. `fk`), `FieldRenderer`, `buildRepository`, recipe
> (`manifest-spec.md`), and **16 master packages** (Org + Inventory flat + Dept/Designation)
> are in tree. Full entity matrix + next sprints: [`STATUS.md`](./STATUS.md). Sections §1 / §7 / §8
> below were refreshed to match code; remaining wave checkboxes still use historical wording
> where a task is only half-met.

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

### 1.2 Track A — Reuse Keystone  `[x]` DONE (v1 scope); expanded A0 still `[~]`

**Present** under `lib/core/{data,bloc,utils,di}`:

| Artifact | State | Gap vs original A0 wishlist |
|----------|-------|--------------------------|
| `RemoteDataSourceBase` | Implemented | — |
| `RemoteRepository` | Implemented + tests | — |
| `buildRepository` / RepoBinding helper (A0.2) | **Done** (`repo_binding.dart`) | — |
| `CrudBloc<E,ID,F>` | Implemented + tests | Pagination/search inlined + `debounceRestartable` — accepted |
| `DetailBloc` | Implemented, used by form pages | Dedicated unit tests still thin |
| `FormMixin` | Used by Auth + MasterFormSurface | Deeper dirty/submit FormController (A0.3) still optional |
| `ClientQuery` adapter (A0.4) | **Not built** | BE-002/003/004 workaround |
| Idempotency-Key interceptor (A0.5) | **Not built** | BE-005 / CR-004 |
| Deviations documented (A0.1) | **Partial** | Prefer `feature-contract.md` + `STATUS.md` |

### 1.3 Status of the rest (2026-07-12)

- **Track B — Identity & Access:** `[x]` DONE. `lib/features/auth/**`, fail-open RBAC, router guards.
- **Track C — Widget library:** `[x]` DONE. `lib/core/widgets/**`, catalog, gallery.
- **Wave A3 EMR core:** `[~]` **usable** — list + form surfaces, FieldRenderer, fk/int/decimal/bool; missing `selfFk`, `binary`, ManifestRegistry, command palette. See §7.
- **Wave A4 gold path:** `[x]` Brand **full CRUD** + Designation **FK** + recipe (`manifest-spec.md`). See §8.
- **Wave A5 masters:** `[~]` **16 of ~50+** registered (Org/Inventory flat + HR dept/designation). Accounts **0**. Exceptions in `manifest-exceptions.md`. Matrix: `STATUS.md`.
- **Not started:** A6 DocumentSurface / Line Engine · A7 voucher blueprints · A8 dashboard/reports/palette · A9 polish/QA · offline (parked).

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

- [~] **A0.1** Document intentional deviations — partially in `feature-contract.md` / `STATUS.md`; full note optional
- [x] **A0.2** `buildRepository` in `lib/core/di/repo_binding.dart` — used by master `*_di.dart` factories
- [~] **A0.3** Form submit lifecycle — present on `MasterFormSurface` (`_submitting`, field errors); dedicated FormController still optional
- [ ] **A0.4** **ClientQuery** adapter (`lib/core/data/client_query.dart`)
- [ ] **A0.5** **Idempotency** interceptor — `Idempotency-Key` on POST
- [~] **A0.6** Core tests present (CrudBloc, RemoteRepository path, FormMixin, surfaces); DetailBloc / ClientQuery still thin
- [~] **A0.7** Track A engine solid; expanded A0 not fully closed

**Done-when (expanded):** ClientQuery + idempotency + analyze/tests green. **Practical done-when (met):** masters ship on `buildRepository` + CrudBloc without per-entity engines.

---

## 5. Wave A1 — Identity & Access  `[x]` DONE

**Folders:** `lib/features/auth/`, `lib/core/auth/`

- [x] Login / refresh / me / change-password / logout
- [x] Token storage wiring
- [x] `AuthBloc` sealed states
- [x] `FailOpenPermissionService` until BE-001
- [x] `PermissionGate` + go_router redirect (login / 403)
- [~] Company/branch/FY session chrome (session bar partial)
- [x] Auth tests

**Done-when:** met for online auth shell.

---

## 6. Wave A2 — Widget atoms + gallery  `[x]` DONE (charts optional leftover)

**Folders:** `lib/core/widgets/`, `docs/widget-catalog.md`

- [x] `docs/widget-catalog.md`
- [x] Typed fields: text / number / decimal / date / currency / switch / dropdown
- [x] Status chips, confirm dialog, filter bar
- [ ] File/image picker, KPI card polish, owned sparklines (defer to A8 desk)
- [x] `AsyncStateView` over `ViewState`
- [x] Gallery: light/dark × LTR/RTL route
- [x] Async FK lookup (`fk_lookup_field`)
- [x] Adaptive entity list bound to list surfaces / CrudState
- [x] Line-item grid widget exists (voucher totals engine not wired — A6)

**Done-when:** met for master CRUD atoms.

---

## 7. Wave A3 — ★ Entity Manifest Runtime (core differentiator)  `[~]` USABLE

**Folders:** `lib/core/manifest/`, `lib/core/surfaces/`, `docs/manifest-spec.md`

### A3.1 Manifest model  `[~]`

- [x] `FieldType`: `text`, `dateTime`, `int`, `decimal`, `bool`, `fk`
- [ ] `selfFk`, `enum`, `json`, `binary` — still deferred (see STATUS Sprint A / exceptions)
- [x] `FieldSpec<E>` list columns
- [x] `FormFieldSpec<E>` with wireKey, validators, FK triple
- [x] `EntityManifest<E>`: list + form + hardDelete + supportsUpdate/Delete + emptyEntity
- [ ] `formSections` / `treeParentField` / ManifestRegistry

### A3.2 Binding layer  `[~]`

- [x] Hand-written DTO + Mapper per entity (no freezed required)
- [x] `buildRepository` DI helper — all masters use it
- [ ] Central ManifestRegistry / injectable master bindings (not required at current scale)

### A3.3 Surfaces  `[~]`

- [x] `MasterListSurface`
- [x] `MasterFormSurface` (edit doubles as read-only when `supportsUpdate: false`)
- [ ] Separate `MasterDetailSurface` — **wontfix** unless form-as-view fails UX
- [x] `FieldRenderer`
- [ ] Generic `/m/:manifestId` route factory — still per-entity routes

### A3.4 ★ Command palette  `[ ]` stub in shell header only

### A3.5 Spec & tests  `[x]` / `[~]`

- [x] `docs/manifest-spec.md` recipe (post Brand + Designation)
- [x] List + form surface tests + field_renderer tests
- [ ] Registry / ClientQuery tests — N/A until those land

**Done-when (full A3):** registry + selfFk/binary + palette. **Practical done-when (met):** masters register via 7-file recipe without new Surfaces.

---

## 8. Wave A4 — Gold path: Brand + hard-case master  `[x]` DONE (selfFk still open)

- [x] Brand full list + create/edit/delete (hard delete)
- [x] DI + menu + routes
- [x] Designation **FK** hard case → Department
- [x] `docs/manifest-spec.md` recipe
- [ ] AccountGroup **selfFk** tree — next (STATUS Sprint A)
- [x] Brand + Designation mapper tests; shared surface tests

**Done-when:** met for Brand CRUD + FK proof. Self-FK remains Sprint A unlock.

---

## 9. Wave A5 — Register remaining masters (not clone them)  `[~]` IN PROGRESS

For each module, work is **DTO + mapper + manifest + DI + thin pages**, not new Surfaces.

| Parallel unit | Status |
|---------------|--------|
| ∥ Organization | **5 shipped** (Branch, Currency, Role, Contact, FY); rest `[!]`/`[ ]` in STATUS |
| ∥ Accounts | **2 shipped** (AccountGroup flat, Ledger core) |
| ∥ Inventory | **13 shipped** flat + Item/Group/SKU/Batch; image still deferred |
| ∥ Employee | **2 shipped** (Department, Designation) |
| ∥ Ancillary | **0** |

**Rules:**

- [x] No new list/form widgets inside a feature (recipe enforced)
- [x] Exceptions → `docs/manifest-exceptions.md`
- [ ] 1:1 extensions as form sections (Ledger bank/credit/tax — Sprint A phase 2)
- [ ] Hierarchical `treeParentField` + tree picker (`selfFk`)

**Done-when:** coverage matrix in STATUS green for all listable masters; not met.

**Next:** STATUS §4 Sprint A (AccountGroup + LedgerMaster).

---

## 10. Wave A6 — ★ Document Surface + Sales Invoice gold  `[~]`

Vouchers are not manifests of flat fields alone — they are **blueprints**.

### A6.1 Decimal Line Engine (domain kernel)

- [x] Pure Dart: line net, tax, discount, document totals — all `Decimal`
- [x] Unit tests matching backend posting math (discount then tax-on-net, 2dp)
- [x] Zero UI dependency (`lib/core/domain/line_engine/`)

### A6.2 `VoucherBlueprint`

- [x] party / lineShape / flags / lifecycle / endpoints / rbacModule
- [x] Seed: `VoucherBlueprints.salesInvoice`

### A6.3 DocumentSurface

- [x] Header slot + line grid bound to Line Engine + totals + Post (RBAC)
- [ ] Save draft vs post for types that support Draft
- [ ] List filters / ClientQuery
- [ ] Read-only view + GL preview
- [ ] Full lifecycle toolbar (approve/reject/cancel + reason)
- [ ] Print-friendly layout

### A6.4 Sales Invoice gold

- [x] Blueprint + list + post form (`transactions_sales_invoice`)
- [x] `docs/templates/voucher-blueprint-recipe.md` + `voucher-type-matrix.md`
- [x] Tests: Line Engine + SI DTO

**Done-when (MVP):** Create and post Sales Invoice online; totals stable; template ready.  
**Still open:** detail view, cancel/approve UI, draft-only path polish.

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

1. Use **[`STATUS.md`](./STATUS.md)** for completion matrix + sprint notes.
2. **Sprint A remainder:** `FieldType.selfFk` → parent on AccountGroup/InventoryGroup; ledger bank/credit/tax tabs.
3. **Sprint D:** Register next voucher blueprints on DocumentSurface (Purchase SI, Payment, …).
4. Do **not** mass-clone feature packages; keep the 7-file EMR recipe.
5. Leave offline (`database/**`, CRs) parked until online trading path works.
6. Keep wave narrative here; flip STATUS marks when shipping entities.

---

## 18. Supersession notice

When execution switches fully to v2, add at the top of `docs/BUILD_TASKS.md`:

```markdown
> **Superseded by `docs/BUILD_TASKS_V2.md` (manifest-driven plan).**
> Keep this file for historical context of Waves 0–1 doctrine (R1–R7 still apply).
```

Doctrine **R1–R7** remains binding. Only the **scale strategy** changes: from “stamp features” to “declare manifests / blueprints and render Surfaces.”
)
