# Prompt Execution Plan — Flutter ERP Frontend (algoERP)

## Context

The backend (`E:\work\algo-backend\models\backend`, TypeScript/Express/Prisma + MySQL) is **complete**: ~**310 endpoints** across **12 route groups**, **86 entities** in 5 domain modules, JWT auth with fine-grained RBAC, multi-tenant scoping, double-entry GL posting, a voucher lifecycle state machine, and an OpenAPI spec. The Flutter frontend is **greenfield** (working dir `E:\work\algo-backend\front`, currently empty).

This document is **not** the implementation. It is an ordered, dependency-aware **sequence of copy-pasteable prompts** to build the entire frontend, with per-step LLM routing (Opus designs the templates; Gemini Flash stamps them across entities). Each prompt is self-contained (paste the *Standard Context Header* on top) so steps can run in separate sessions.

### Locked decisions (from the requester)
- **Data layer:** Hand-rolled Clean Architecture **gold template + Flash mass-stamp** (max control, max reuse).
- **Persistence:** **Full offline-first sync** — local DB is the source of truth; a sync engine reconciles with the API. *(Heaviest option; drives Core steps 5–7 and several CRs.)*
- **Design system:** I design a modern **Material 3** default (tokens, light/dark, motion). Data is **UAE-centric** (TRN/VAT, AED, `*_arabic` fields) ⇒ **RTL + Arabic localization** is in scope.
- **Navigation:** **Truly adaptive** shell (Drawer ↔ NavigationRail ↔ extended sidebar; list ↔ master-detail per breakpoint). Targets: iOS, Android, Web, Desktop.

### Intentional deviation from the meta-prompt's "ONE reference slice"
The backend has **two fundamentally different archetypes**, so there are **two gold templates**, each built once by Opus then stamped by Flash:
- **Archetype A — Master-data CRUD** (40 entities): list / detail / create / edit / soft-delete.
- **Archetype B — Transactional voucher document** (18 documents): header + dynamic line-item grid + running totals + lifecycle (Draft→Approved→Posted→Cancelled/Rejected) + server-side posting (GL/stock/billwise) + offline "pending-sync" handling.

---

## Backend facts every prompt depends on (ground truth)

**Response envelope** (`src/core/types/index.ts`):
```jsonc
// success
{ "success": true, "message": "optional", "data": { /* T */ }, "requestId": "uuid" }
// error
{ "success": false, "error": { "message": "...", "code": "optional", "details": [/* zod issues */] }, "requestId": "uuid" }
// paginated data payload
{ "items": [ /* T[] */ ], "meta": { "total": 0, "page": 1, "limit": 20, "totalPages": 0 } }
```
- **Auth:** `Authorization: Bearer <accessToken>`. Login `POST /auth/login {username,password}` → tokens; refresh `POST /auth/refresh {refreshToken}`; `GET /auth/me`; `POST /auth/change-password`; `POST /auth/logout`. JWT claims: `userId, username, roleId, branchId, companyId`.
- **Tenancy:** primarily from token; fallback headers `X-Company-Id` / `X-Branch-Id`.
- **Tracing:** send/propagate `X-Request-Id` (uuid).
- **RBAC:** every protected route runs `authorize(moduleName, action)` where action ∈ `create|read|update|delete|share`. Module names are PascalCase (e.g. `SalesInvoice`, `Accounts`, `Inventory`, `CompanyProfile`, `Employee`, `PaymentVoucher`). The UI must gate menus/buttons by the current role's permissions.
- **Pagination query:** `page` (default 1), `limit` (default 20). **Soft-delete:** `is_active`. **Money/qty:** Decimal — never `double`; use the `decimal` package and serialize as string.
- **Route mounts (no `/api/v1`):** `/auth`, `/organization`, `/accounts`, `/inventory`, `/employee`, `/transactions`, `/reports`, plus `/health`, `/ready`, `/docs` (Swagger), OpenAPI source at `src/core/docs/openapi.ts`.

**Module → entity map (86 entities):**
- **Organization (11):** CompanyProfile, FinancialYear, Branch, Currency, CurrencyRate, VoucherSeries, AddressBook (contacts), UserRole, UserCredentials, Permissions, ProjectMaster.
- **Accounts (4):** AccountGroup (tree), LedgerMaster (+ 1:1 bank/credit/tax extensions), BillwiseRecord, ChequeDetails. Plus read endpoints: balance, outstanding, aging.
- **Inventory (19):** UOM, Brand, Category, TaxCategory, InventoryGroup (tree), InventoryItem (rich), SKUMaster, ItemBatch, ItemProperty, ItemImage, Ingredient (BOM), Godown, UOMConversion, PriceList, PriceListEntry, RouteMaster, RouteCustomerMapping, RouteMapping, LedgerItemMapping. Plus stock-ledger / stock-balance reads.
- **Employee/HR (14):** Department (tree), Designation, EmployeeDetails (+ 1:1 bank/salary), EmployeeDocument, SalaryRevisionHistory, LeavePolicy, LeaveAllocation, LeaveRequest (workflow), AttendanceDetails, ShiftMaster, EmployeeShiftAssignment, PayslipMain, plus reports (overtime, attendance-summary).
- **Transactions (38):** 18 voucher documents (Quotation, SalesOrder, PurchaseOrder, SalesInvoice, PurchaseInvoice, Payment, Receipt, Contra, Journal, CreditNote, DebitNote, DeliveryNote, ReceiptNote, GodownTransfer, MaterialIn, Requirement, StockRequest, Payslip) + infra (VoucherHeader, JournalLedger, VoucherLineAllocation, Shipment, ItemPhysicalSpec, VoucherLinkage, TermsAndConditions, TransportationDetails). Cross-cutting: dashboard, alerts, global search, reports (sales/purchase register, trial-balance, P&L, balance-sheet, day-book, ledger-statement, stock-summary/valuation, VAT return), voucher lifecycle (edit/approve/cancel/reject).

**Voucher posting semantics (drives Template B + offline rules):** server auto-generates the voucher number (atomic mutex per type/prefix/FY), posts double-entry GL (`Σdebit=Σcredit`), writes stock_ledger and billwise rows, enforces credit-limit + max-discount. ⇒ **Offline-created vouchers cannot get a real number/GL until synced** → they live as local `pendingSync` drafts with a temp number and a sync-status badge.

---

## Tech stack (assume across all prompts unless a step overrides)

| Concern | Choice | Note |
|---|---|---|
| State mgmt | `flutter_bloc` | sealed states via Dart 3 |
| DI | `get_it` + `injectable` | |
| Routing | `go_router` | adaptive ShellRoute, auth + RBAC redirect guards |
| Network | `dio` (+ `dio_smart_retry`, logger) | interceptors: auth/refresh, tenant, requestId, error-map |
| Models | `freezed` + `json_serializable` | immutable DTOs + entities |
| Functional errors | `fpdart` (`Either<Failure, T>`) | |
| Local DB (source of truth) | `drift` | web (WASM), desktop, mobile; reactive streams |
| Sync | custom engine + `connectivity_plus` + `workmanager` | outbox + delta-pull |
| Money | `decimal` | never `double` |
| Equality | freezed / `equatable` | |
| i18n / RTL | `flutter_localizations` + `intl` (ARB) | English + Arabic, RTL-aware |
| Testing | `bloc_test`, `mocktail`, `integration_test`, `alchemist` (golden) | |

---

## STANDARD CONTEXT HEADER (paste at the TOP of every step's prompt)

> You are a **Principal Flutter Architect** building the greenfield Flutter frontend for **algoERP**, a multi-platform (iOS/Android/Web/Desktop) ERP. Project root: `E:\work\algo-backend\front`. The Node/Express/Prisma+MySQL backend is COMPLETE.
>
> **Non-negotiables:** Clean Architecture (domain/data/presentation), `flutter_bloc` for all state, **offline-first** (local **drift** DB is the source of truth; a sync engine reconciles with the API), **truly adaptive** UI (Drawer↔Rail↔sidebar; list↔master-detail), **Material 3** design system with light/dark + motion, **RTL/Arabic** localization (data has `*_arabic`, TRN/VAT, AED), and **aggressive reuse** via Dart generics/sealed classes/mixins/extensions — no duplicated widget or bloc code.
>
> **API contract:** Base routes mount at root (`/auth`, `/organization`, `/accounts`, `/inventory`, `/employee`, `/transactions`, `/reports`). Auth = `Authorization: Bearer <token>` (+ refresh at `/auth/refresh`); tenancy via token claims `companyId/branchId` (fallback `X-Company-Id`/`X-Branch-Id`); propagate `X-Request-Id`. Success = `{success, message?, data, requestId}`; error = `{success:false, error:{message, code?, details?}, requestId}`; lists = `{items, meta:{total, page, limit, totalPages}}` with `?page&limit`. Soft-delete via `is_active`. Money/qty = Decimal (string), use `decimal`, never `double`. RBAC: gate UI by `(moduleName PascalCase, action create|read|update|delete|share)` from the role's permissions.
>
> **Stack:** flutter_bloc, get_it+injectable, go_router, dio, freezed+json_serializable, fpdart (Either<Failure,T>), drift, connectivity_plus+workmanager, decimal, flutter_localizations+intl.
>
> **Folder layout (feature-first Clean Architecture):**
> ```
> lib/core/{config,theme,responsive,navigation,network,error,database,sync,usecase,bloc,di,utils,widgets}
> lib/features/<feature>/{domain/{entities,repositories,usecases},data/{models,mappers,datasources,repositories},presentation/{bloc,pages,widgets}}
> lib/l10n/  •  lib/main_<flavor>.dart
> ```
> **When you find a backend gap/ambiguity, do NOT guess — emit a Change Request** `.md` into `docs/change-requests/` using the CR template, and continue with a clearly-marked assumption.

---

## The Prompt Execution Plan

> Legend — **Opus** = architecture/template/one-wrong-decision-propagates work. **Flash** = high-volume stamping of a settled template. Most steps depend strictly on earlier ones (the "dependency spine").

---

### Step 0 — Discovery, API Contract & CR Scaffolding
- **Goal:** Freeze a machine-checkable feature inventory + API contract + offline-sync readiness audit; create the CR system.
- **Depends on:** none.
- **Recommended LLM:** **Opus 4.8** — discovery accuracy gates everything; misreading a contract propagates into 86 entities.
- **The Prompt:**
  > [STANDARD CONTEXT HEADER]
  > Task: Produce the authoritative discovery artifacts the rest of the build depends on. Read the backend at `E:\work\algo-backend\models\backend\src` (routes/controllers/schemas/enums per module) and `src/core/docs/openapi.ts`.
  > 1. Write `docs/feature-inventory.md`: every module → every entity → fields (type, required, FK), enums, and classify each as **Master-CRUD** or **Voucher-document** (note header→lines + posting/lifecycle for documents). Include the full endpoint table per module (METHOD, PATH, RBAC `module:action`, purpose).
  > 2. Write `docs/api-contract.md`: the exact success/error/pagination envelopes, auth + refresh flow, tenancy headers, requestId, RBAC model + the full list of `moduleName` values and actions, soft-delete + Decimal conventions, and the per-entity request/response field lists for ONE representative master (e.g. `Brand`) and ONE document (`SalesInvoice`).
  > 3. Write `docs/offline-sync-readiness.md`: audit whether the backend supports offline sync — delta/changed-since query params, server `updated_at` in list payloads, soft-delete tombstones in deltas, idempotency keys on POST, bulk hydration endpoints. For each missing capability, emit a Change Request.
  > 4. Create `docs/change-requests/` with `_TEMPLATE.md` (see CR template) and `README.md` (index). File CRs for every gap found here and the known gaps: Quotation→SalesOrder conversion endpoint, stock-ledger read filters, trial-balance/P&L/balance-sheet confirmation, receipt/payment settlement-allocation API, audit-log read endpoint.
  > Do not write Flutter code yet.
- **Expected artifacts:** `docs/feature-inventory.md`, `docs/api-contract.md`, `docs/offline-sync-readiness.md`, `docs/change-requests/_TEMPLATE.md`, `docs/change-requests/README.md`, initial CR files.
- **Done-when:** Every endpoint and entity is catalogued; the offline-sync CRs exist; contracts match `src/core/types/index.ts` exactly.

---

### Step 1 — Project Scaffold, Clean Architecture Skeleton & Dependencies
- **Goal:** Runnable empty app with the full folder tree, deps, flavors, lint, CI.
- **Depends on:** 0.
- **Recommended LLM:** **Opus 4.8** — folder/layer + DI + flavor decisions propagate everywhere.
- **The Prompt:**
  > [STANDARD CONTEXT HEADER]
  > Task: `flutter create` the app in `E:\work\algo-backend\front` for all platforms. Add every dependency from the stack table to `pubspec.yaml` (with build_runner, drift_dev, injectable_generator, json_serializable, freezed). Create the EXACT folder layout from the header (with `.gitkeep`/barrel files). Configure: `analysis_options.yaml` (very_good_analysis or strict lints), three **flavors** (dev/staging/prod) with per-flavor `--dart-define` base URLs and `main_<flavor>.dart` entrypoints, `get_it`+`injectable` bootstrap (`configureDependencies()`), `flutter_localizations`+`intl` with `l10n.yaml` (en + ar ARB stubs, RTL aware), and a minimal `App` widget that renders an empty adaptive scaffold + runs on web/desktop/mobile. Add a `Makefile`/`melos`-style scripts doc and a GitHub Actions lint+test workflow. No features yet.
- **Expected artifacts:** Full `lib/` tree, `pubspec.yaml`, `analysis_options.yaml`, `l10n.yaml`, 3 flavor entrypoints, `core/di/injection.dart`, CI workflow.
- **Done-when:** `flutter analyze` clean; app launches on web + one desktop target showing the empty shell; `dart run build_runner build` succeeds.

---

### Step 2 — Core: Design System (Material 3 tokens, themes, motion, RTL)
- **Goal:** The visual foundation: tokens, light/dark themes, typography, spacing, motion, RTL.
- **Depends on:** 1.
- **Recommended LLM:** **Opus 4.8** — the token system + theme extension API is reused by every widget/screen.
- **The Prompt:**
  > [STANDARD CONTEXT HEADER]
  > Task: Build `lib/core/theme/`. Define a **design-token** layer (color roles, semantic colors incl. success/warning/danger/info + voucher-status colors, spacing scale, radii, elevation, typography scale, durations/curves for motion) exposed via a custom `ThemeExtension` (`AppTokens`) so widgets never hardcode values. Provide `lightTheme`/`darkTheme` (Material 3, `ColorScheme.fromSeed` + overrides), density tuned for data-dense ERP screens, and a `MotionTokens` set (page transitions, list stagger, hover/press micro-interactions). Wire `ThemeMode` switching via a `ThemeCubit` (persisted). Ensure **RTL** correctness (Directionality, logical insets) and that `MaterialApp.router` consumes `supportedLocales` en+ar. Deliver a `/theme-preview` route showing the full token catalog (colors, type ramp, buttons, status chips) in light/dark/LTR/RTL.
- **Expected artifacts:** `core/theme/{tokens,app_theme,motion,theme_cubit}.dart`, theme-preview page.
- **Done-when:** Toggling light/dark and LTR/RTL re-themes the preview correctly; no hardcoded colors/sizes outside tokens.

---

### Step 3 — Core: Responsive Framework & Adaptive Navigation Shell
- **Goal:** Breakpoint system + the adaptive shell (Drawer↔Rail↔sidebar) + adaptive layout primitives.
- **Depends on:** 2.
- **Recommended LLM:** **Opus 4.8** — the responsive + nav contract is consumed by every page; mistakes are systemic.
- **The Prompt:**
  > [STANDARD CONTEXT HEADER]
  > Task: Build `lib/core/responsive/` and `lib/core/navigation/`. Responsive: a `Breakpoints` system (mobile/tablet/desktop/large) + `ResponsiveBuilder`, `AdaptiveLayout`, and a `MasterDetailLayout` (stacked navigation on small screens, side-by-side panes on large). Navigation: `go_router` config with a `ShellRoute` hosting an **adaptive navigation shell** that renders a bottom bar/drawer on mobile, a `NavigationRail` on tablet, and an extended labeled sidebar on desktop — driven by breakpoints, with a data-driven menu model (sections/items/icons/route/required `module:action`). Include route definitions placeholders for all modules, deep-link support, and redirect guards stubs (auth + RBAC) to be wired in Step 8. Provide page-transition wiring using `MotionTokens` from Step 2.
- **Expected artifacts:** `core/responsive/*`, `core/navigation/{app_router,app_shell,menu_model}.dart`.
- **Done-when:** Resizing the window morphs the shell across all three layouts; master-detail collapses/expands; menu is data-driven.

---

### Step 4 — Core: Network Layer (Dio, interceptors, envelope, errors)
- **Goal:** Typed HTTP client that speaks the exact envelope and maps everything to `Either<Failure,T>`.
- **Depends on:** 1.
- **Recommended LLM:** **Opus 4.8** — the `ApiResult`/`Failure` contract is the seam between data sources and the whole app.
- **The Prompt:**
  > [STANDARD CONTEXT HEADER]
  > Task: Build `lib/core/network/` and `lib/core/error/`. Implement a `DioClient` (per-flavor base URL) with interceptors: (a) **Auth** — attach `Authorization: Bearer`, on 401 attempt `/auth/refresh` once and replay (queue concurrent requests during refresh); (b) **Tenant** — inject `X-Company-Id`/`X-Branch-Id` when present; (c) **RequestId** — generate+attach `X-Request-Id`; (d) logging. Model the envelope with generics: `ApiResponse<T>`, `Paginated<T>` (matching backend `{items, meta:{total,page,limit,totalPages}}`), and a `decode<T>(json, fromJson)` helper. Define a sealed `Failure` hierarchy (network/timeout/unauthorized/forbidden/validation[with field errors from `error.details`]/notFound/server/cache/conflict) and a `Result<T> = Either<Failure,T>`. Provide a `safeCall` wrapper that converts Dio errors → Failure. Unit-test the envelope decode + error mapping with mocktail.
- **Expected artifacts:** `core/network/{dio_client,interceptors/*,api_response,paginated,safe_call}.dart`, `core/error/{failure,exceptions}.dart`, tests.
- **Done-when:** Tests prove success/error/paginated decode + 401-refresh-replay + validation-field extraction.

---

### Step 5 — Core: Local Database (drift) & Offline Foundations
- **Goal:** The on-device source of truth + per-entity sync metadata + base DAO.
- **Depends on:** 1.
- **Recommended LLM:** **Opus 4.8** — the local schema + sync-metadata design underpins every repository.
- **The Prompt:**
  > [STANDARD CONTEXT HEADER]
  > Task: Build `lib/core/database/`. Set up **drift** with a multi-platform connection (mobile/desktop native, web WASM). Define a **convention for entity tables** that mirror backend resources plus **sync columns** on every table: `localId` (uuid PK), `serverId` (nullable int), `syncStatus` (synced|pendingCreate|pendingUpdate|pendingDelete|conflict), `updatedAtServer`, `updatedAtLocal`, `isActive`, `dirtyFields` (json), `version`. Add a generic `BaseDao<T>` with reactive `watch`/paginated queries/upsert-from-server/mark-dirty. Add an **id-mapping** table (localId↔serverId) and an **outbox** table (mutation queue: entity, op, payload json, idempotencyKey uuid, attempts, lastError, createdAt). Provide a DB-reset + migration strategy. Demonstrate the convention with ONE table (`brands`) end-to-end (no UI). Document the table-generation convention so Flash can replicate it.
- **Expected artifacts:** `core/database/{app_database,connection/*,base_dao,tables/sync_columns,tables/outbox,tables/id_map}.dart`, generated drift code, convention doc.
- **Done-when:** DB opens on web + desktop; `brands` table watch-stream + outbox insert works in a test.

---

### Step 6 — Core: Sync Engine (outbox push, delta pull, conflicts, scheduler)
- **Goal:** The reconciliation engine: push local mutations, pull deltas, resolve conflicts, run in background.
- **Depends on:** 4, 5; informed by Step 0's offline-sync CRs.
- **Recommended LLM:** **Opus 4.8** — the hardest, most cross-cutting subsystem; correctness is critical for an accounting app.
- **The Prompt:**
  > [STANDARD CONTEXT HEADER]
  > Task: Build `lib/core/sync/`. Implement: (a) **Connectivity** monitor (`connectivity_plus`) exposing online/offline as a stream; (b) **Outbox processor** — drains the queue in dependency order, replays each mutation to the API with its `idempotencyKey`, maps returned `serverId`/voucher-number back into local rows, handles 409/validation by flagging `conflict`; (c) **Delta puller** — per-entity `?updatedSince=<cursor>` pulls (incl. tombstones for soft-deletes), upserting into drift and advancing cursors; (d) **Conflict policy** — last-write-wins for masters (server timestamp), **server-authoritative** for vouchers (local pending voucher keeps temp number until server posts → then adopt real number + GL); (e) a `SyncScheduler` (foreground triggers on reconnect + periodic; `workmanager` background on mobile); (f) a `SyncStatusCubit` + UI-facing per-record status. If a required backend capability is missing (delta params, idempotency, tombstones), CODE AGAINST AN ABSTRACTION and emit/append the CR; provide a temporary full-refresh fallback. Test: offline create→queue→reconnect→push→id-adoption, and a conflict path.
- **Expected artifacts:** `core/sync/{connectivity,outbox_processor,delta_puller,conflict_resolver,sync_scheduler,sync_status_cubit}.dart`, tests, updated CRs.
- **Done-when:** Tests show offline mutation survives restart, pushes on reconnect, adopts server id; conflicts are flagged not lost.

---

### Step 7 — Core: Base Abstractions (UseCase, OfflineFirstRepository, generic CRUD Bloc)
- **Goal:** The reuse keystone — generics/sealed/mixins that every feature inherits so screens are thin.
- **Depends on:** 4, 5, 6.
- **Recommended LLM:** **Opus 4.8** — this is THE abstraction layer; one design here removes thousands of duplicated lines.
- **The Prompt:**
  > [STANDARD CONTEXT HEADER]
  > Task: Build `lib/core/usecase/` and `lib/core/bloc/`. Provide: a base `UseCase<Out,In>`/`NoParams`; an abstract **`OfflineFirstRepository<E>`** capturing the canonical flow (read from drift first → emit → trigger sync; writes go local + outbox), parameterized by a remote datasource, a local DAO, and a mapper, with hooks for entity-specific endpoints; a **generic `CrudBloc<E, F>`** (events: load/loadMore/refresh/create/update/delete/search/filter; sealed states: initial/loading/loaded(items,meta,hasMore)/error; supports server pagination + local stream merge); a `DetailBloc<E>`; a `FormBloc` mixin for validation; reusable **mixins** (`PaginationMixin`, `SearchDebounceMixin`, `RbacMixin`) and **extensions** (Either→state, Decimal/date formatting, BuildContext.tokens/.l10n/.breakpoint). Document exactly what a feature must supply to reuse all of this (the "feature contract" Steps 10/12 follow). Unit-test `CrudBloc` with a fake repo via bloc_test.
- **Expected artifacts:** `core/usecase/usecase.dart`, `core/bloc/{crud_bloc,detail_bloc,form_bloc,mixins/*}.dart`, `core/utils/extensions/*`, repository base, feature-contract doc, tests.
- **Done-when:** `CrudBloc` passes bloc_tests for load/paginate/create/delete/error against a fake repo; feature-contract doc is concrete.

---

### Step 8 — Cross-cutting: Auth, Session & RBAC Gating
- **Goal:** Login/refresh/logout/change-password, session bootstrap, and permission-driven UI gating + route guards.
- **Depends on:** 3, 4, 6, 7.
- **Recommended LLM:** **Opus 4.8** — auth/session/RBAC is security-sensitive and wired into routing + every screen.
- **The Prompt:**
  > [STANDARD CONTEXT HEADER]
  > Task: Build `lib/features/auth/` end-to-end (domain/data/presentation) + `lib/core/auth/`. Implement login (`POST /auth/login`), token refresh, `GET /auth/me`, change-password, logout; secure token storage (`flutter_secure_storage` mobile/desktop, safe web fallback); an `AuthBloc` exposing `authenticated(user, permissions, companyId, branchId)`/`unauthenticated`. Fetch the role's permission matrix and expose a `PermissionService` + `can(module, action)` + a `PermissionGate` widget and `RbacMixin` so menus/buttons/routes hide or disable per permission. Wire `go_router` redirect guards (unauthenticated → /login; missing-permission → 403 page). Build a polished adaptive **login page** (Step 2/3 tokens + motion). Handle multi-company/branch selection if the user has several. Tests: auth bloc flows + guard redirects.
- **Expected artifacts:** `features/auth/**`, `core/auth/{token_storage,permission_service,permission_gate}.dart`, router guards, login page, tests.
- **Done-when:** Real login against a running backend succeeds, token auto-refreshes, and a low-permission role sees a correctly gated menu.

---

### Step 9 — Reusable Widget Library (catalog → build)
- **Goal:** Catalog every widget archetype, then build the shared library BEFORE feature screens.
- **Depends on:** 2, 3, 7.
- **Recommended LLM:** **Opus 4.8** for the abstraction/API + complex widgets; **Gemini Flash** for simple variants once the API is fixed.
- **The Prompt (Opus):**
  > [STANDARD CONTEXT HEADER]
  > Task: First write `docs/widget-catalog.md` — enumerate every UI widget needed across the two archetypes and cross-cutting screens (buttons, inputs/typed fields [text, number/decimal, date, currency, switch, dropdown-enum], **async FK lookup field** [searchable, paginated], **adaptive data table / card-list** with sort+select+pagination, **dynamic line-item editor grid** with add/remove/reorder + running totals, status chips, **sync-status badge**, empty/loading(skeleton)/error states, confirm dialogs, snackbars/toasts, filter bar, page scaffold with breadcrumbs, tabs/section cards, file/image picker, stat/KPI card, chart wrappers). For each: purpose, props/API, responsive behavior, RTL notes. Then BUILD `lib/core/widgets/` implementing the library against the design tokens, fully generic and themable, with a `/widgetbook` (or gallery route) demonstrating each in light/dark/LTR/RTL. Prioritize the complex ones (FK lookup, adaptive table, line-item grid, async-state wrapper) yourself; mark trivial ones as "Flash-stampable" with a fixed signature.
  > Then (Flash follow-up prompt, after Opus): "Implement the remaining widgets marked Flash-stampable in `docs/widget-catalog.md` following the exact signatures and the existing widgets as templates; add each to the gallery."
- **Expected artifacts:** `docs/widget-catalog.md`, `lib/core/widgets/**`, gallery route.
- **Done-when:** Gallery renders every widget in all theme/direction combos; no screen will need bespoke primitives later.

---

### Step 10 — Gold Template A: Master-data CRUD Vertical Slice (offline-first)
- **Goal:** One master entity built end-to-end as the canonical template for the other ~39.
- **Depends on:** 7, 8, 9.
- **Recommended LLM:** **Opus 4.8** — this template is copied ~39×; every decision multiplies.
- **The Prompt:**
  > [STANDARD CONTEXT HEADER]
  > Task: Implement the **Brand** feature (Inventory module, `/inventory/brand`) as the GOLD TEMPLATE for master-data CRUD, exercising the full stack so it generalizes: `domain` (entity, abstract repository, usecases), `data` (freezed DTO + json, mapper, **remote datasource** [list w/ page&limit, get, create, update, soft-delete], **local drift DAO** + table, **OfflineFirstRepositoryImpl** using Step 7 base + outbox), `presentation` (`CrudBloc` wiring, **adaptive list page** [data-table on desktop ↔ cards on mobile, search, pagination, RBAC-gated actions, sync badges], **detail page**, **create/edit form** using shared typed fields + validation, soft-delete confirm). Register DI. Then ALSO pick ONE richer master to prove the template covers harder cases — implement **Designation** (FK→Department via async FK-lookup field) OR **AccountGroup** (self-referential tree + parent selector excluding self/descendants). Write `docs/templates/master-crud-template.md`: a precise, fill-in-the-blanks recipe (file list, naming, what changes per entity: endpoint paths, fields, enums, FKs, RBAC module) that Flash will follow. Add bloc + widget tests.
- **Expected artifacts:** `features/inventory_brand/**`, one richer master feature, `docs/templates/master-crud-template.md`, tests.
- **Done-when:** Brand works offline→online (create offline, sync, edit, delete) on web+desktop+mobile; template doc is mechanical enough for Flash.

---

### Step 11 — Mass Replication: Master-data CRUD across remaining entities
- **Goal:** Stamp the master template across the other ~39 master entities, grouped by module.
- **Depends on:** 10.
- **Recommended LLM:** **Gemini Flash (2.5 Flash class)** — settled template, high-volume repetitive generation; cheap + parallelizable. Escalate any entity with unusual shape back to Opus.
- **The Prompt (run once per module, parallelizable):**
  > [STANDARD CONTEXT HEADER]
  > Task: Using `docs/templates/master-crud-template.md` and the `Brand` feature as the EXACT pattern, generate the full offline-first CRUD vertical slice for each master entity in the **<MODULE>** module listed below, reading field/enum/FK/endpoint/RBAC details from `docs/feature-inventory.md` and `docs/api-contract.md`. Entities: <paste the module's master list, e.g. Organization: CompanyProfile, FinancialYear, Branch, Currency, CurrencyRate, VoucherSeries, AddressBook, UserRole, UserCredentials, Permissions, ProjectMaster>. For each: domain+data+presentation+DAO/table+DI, list/detail/form pages, drift table with sync columns, tests scaffold. Reuse all shared widgets/blocs — write NO new primitives. For 1:1 extensions (e.g. LedgerMaster bank/credit/tax), render tabbed sections on the form. For hierarchical entities, reuse the tree/parent-selector from the template. If any entity does not fit the template, STOP and emit a note + CR instead of improvising.
  > Run the same prompt for modules: Organization, Accounts (masters), Inventory (remaining), Employee (masters), Transactions ancillary (TermsAndConditions, TransportationDetails).
- **Expected artifacts:** ~39 feature folders under `lib/features/**`, drift tables, DI registrations, test scaffolds.
- **Done-when:** `flutter analyze` clean; each module's masters list/create/edit/delete offline-first; DB migration regenerated.

---

### Step 12 — Gold Template B: Transactional Voucher Document Vertical Slice
- **Goal:** One full voucher (Sales Invoice) as the canonical template for the other 17 documents.
- **Depends on:** 9, 10, 11 (masters provide FK lookups: ledgers, items, godowns, contacts).
- **Recommended LLM:** **Opus 4.8** — the most complex screen+state in the app (dynamic grid, totals, lifecycle, posting, offline pending-sync); copied 17×.
- **The Prompt:**
  > [STANDARD CONTEXT HEADER]
  > Task: Implement the **Sales Invoice** feature as the GOLD TEMPLATE for transactional documents. Endpoints: create/post `POST /transactions/sales-invoice`; read `GET /transactions/sales-invoices` + `/:id`; lifecycle `PUT /transactions/:type/:id` (edit draft), `POST /transactions/:type/:id/{approve|cancel|reject}`. Build: `domain` (header+line entities, repository, usecases incl. lifecycle actions), `data` (freezed DTOs for header/lines/allocations, mapper, remote datasource, drift tables for header + lines + outbox integration, OfflineFirstRepositoryImpl), `presentation`:
  > - **Voucher entry screen**: header form (customer FK-lookup with live outstanding/credit-limit display, dates, project, branch) + **dynamic line-item grid** (item FK-lookup → auto price/tax, qty, discount%, tax%, per-line + document **running totals** computed with `decimal`, add/remove/reorder rows, optional batch/godown selectors), max-discount validation, save-as-draft vs post.
  > - **Voucher list** (filters: date range, status, customer; status chips) and **voucher view** (read-only posted doc + GL preview + linkages) with **print/PDF** layout.
  > - **Lifecycle state machine** in a bloc: action buttons shown per `voucher_status` (edit if Draft; approve/cancel/reject per RBAC), with confirmation + reason capture.
  > - **Offline rule:** if offline, save as local `pendingSync` draft with a temp number + sync badge; the sync engine posts on reconnect and adopts the server voucher number/GL (server-authoritative). Never fabricate a final number locally.
  > Write `docs/templates/voucher-document-template.md` parameterizing what differs per document type: party field (customer/supplier/none), GL-affecting?, stock-affecting?, godown(s), special fields (e.g. Contra DR/CR lines, Journal debit/credit lines, GodownTransfer from/to). Add bloc + golden tests.
- **Expected artifacts:** `features/sales_invoice/**`, drift header+line tables, `docs/templates/voucher-document-template.md`, tests.
- **Done-when:** Create→post a sales invoice online; create offline→syncs and adopts server number; lifecycle buttons honor status + RBAC; totals match backend math.

---

### Step 13 — Mass Replication: Voucher Documents across remaining 17
- **Goal:** Stamp the document template across the other 17 voucher types, by family.
- **Depends on:** 12.
- **Recommended LLM:** **Hybrid** — **Opus 4.8** to fill the per-type config matrix (party, GL/stock flags, special line shapes, posting nuances) once; **Gemini Flash** to stamp the boilerplate per type from that matrix. (Vouchers vary more than masters, so Opus owns the config decisions.)
- **The Prompt (Opus config, then Flash per family):**
  > [STANDARD CONTEXT HEADER]
  > Opus first: Using `docs/templates/voucher-document-template.md` + `docs/feature-inventory.md`, produce `docs/templates/voucher-type-matrix.md` specifying, for each of the 17 remaining documents, its endpoints, party field, GL-affecting/stock-affecting flags, godown needs, special line structure, lifecycle availability, and any unique fields. Documents & families:
  > - Pre-sales: Quotation, SalesOrder, PurchaseOrder
  > - Sales: DeliveryNote, CreditNote, DebitNote
  > - Purchase: PurchaseInvoice, ReceiptNote
  > - Financial: Payment, Receipt, Journal, Contra
  > - Inventory: GodownTransfer, MaterialIn, StockRequest, Requirement
  > - Payroll: Payslip
  > Flash then: For each document in <FAMILY>, generate the full vertical slice following the Sales Invoice pattern and the matrix row, reusing the line-item grid, lifecycle bloc, and shared widgets. Implement family-specific variants: Journal/Contra use debit/credit (not item) lines; GodownTransfer uses from/to godowns + stock-only; Payment/Receipt use ledger-amount lines + settlement-against-outstanding (use the settlement CR abstraction if endpoint missing). Add tests scaffold. Escalate anything the matrix can't express back to Opus.
- **Expected artifacts:** `docs/templates/voucher-type-matrix.md`, 17 voucher feature folders, drift tables, tests.
- **Done-when:** `flutter analyze` clean; each document creates/lists/views; financial vouchers balance; offline pending-sync works for all.

---

### Step 14 — Cross-cutting: App Shell wiring, Dashboard, Alerts, Global Search
- **Goal:** Assemble the full app — permission-driven menu over all features + dashboard/alerts/search.
- **Depends on:** 8, 11, 13.
- **Recommended LLM:** **Opus 4.8** — composition + dashboard aggregation/layout decisions; partly Flash for repetitive chart cards.
- **The Prompt:**
  > [STANDARD CONTEXT HEADER]
  > Task: Wire the complete navigation menu (all modules/features) into the adaptive shell, each item gated by `module:action` via `PermissionGate`. Build `features/dashboard/`: KPI cards (sales/purchase counts, cash/bank position, top customers) from `GET /reports/dashboard`, an **alerts** panel (expiring docs, overdue bills) from `GET /reports/alerts`, and a **global search** (`GET /reports/search?q=`) surfaced in the top bar with typeahead routing to entities. Use the chart wrappers + KPI cards from Step 9; make the dashboard responsive (grid reflow). Add a settings area (theme, language en/ar, company/branch switch, logout). Tests for dashboard bloc + search debounce.
- **Expected artifacts:** `features/dashboard/**`, completed menu model, top-bar search, settings page.
- **Done-when:** Logged-in user sees a permission-correct menu, a live dashboard, working global search, and language/theme/company switching.

---

### Step 15 — Reports Module (parameterized viewer framework + all reports)
- **Goal:** A reusable report-viewer framework + every backend report with params + export.
- **Depends on:** 9, 14.
- **Recommended LLM:** **Opus 4.8** for the framework; **Gemini Flash** to stamp each report config.
- **The Prompt (Opus framework, then Flash per report):**
  > [STANDARD CONTEXT HEADER]
  > Opus: Build `features/reports/` a **parameterized report framework**: a declarative `ReportDefinition` (params [date range, FY, prefix, ledger/customer pickers], columns, grouping/subtotals, drill-down), a generic `ReportViewer` page (filter bar → adaptive table with subtotals → export to CSV/PDF/Excel), and a `ReportBloc`. Implement ONE report fully (Sales Register, `GET /transactions/reports/sales-register`).
  > Flash: Configure the remaining reports as `ReportDefinition`s wired to their endpoints: purchase-register, stock-summary, stock-valuation, VAT return, trial-balance, P&L, balance-sheet, day-book, ledger-statement, plus Accounts outstanding/aging and Employee overtime/attendance-summary. For any missing backend report (e.g., trial-balance if absent), use the CR abstraction + a placeholder.
- **Expected artifacts:** `features/reports/**` (framework + ~12 report configs), export utils.
- **Done-when:** Each report runs with filters, shows subtotals, and exports; missing ones are CR-tracked.

---

### Step 16 — Polish Pass: Animations, Transitions, Micro-interactions & States
- **Goal:** Apply the motion language + complete empty/loading(skeleton)/error states everywhere.
- **Depends on:** 14, 15.
- **Recommended LLM:** **Opus 4.8** to define the motion/state system; **Gemini Flash** to apply it across screens.
- **The Prompt (Opus design, Flash apply):**
  > [STANDARD CONTEXT HEADER]
  > Opus: Finalize the motion system using `MotionTokens` — page/route transitions (shared-axis/fade-through), list item stagger, hero/expand for master-detail, hover/press/focus micro-interactions, button/loading affordances, and standardized **AsyncStateView** (skeleton loaders, branded empty states with CTA, friendly error states with retry mapped from `Failure`). Document usage rules.
  > Flash: Apply the standardized transitions and AsyncStateView across all list/detail/form/dashboard/report screens, replacing any ad-hoc spinners/empty text. Ensure RTL-correct motion. Add golden tests for key states.
- **Expected artifacts:** `core/widgets/async_state_view.dart`, transition utils, motion-usage doc, updated screens, goldens.
- **Done-when:** Every data screen has skeleton/empty/error states + consistent transitions; goldens pass.

---

### Step 17 — Responsiveness & Multi-platform QA Pass
- **Goal:** Verify and fix layout/behavior across breakpoints and all platforms.
- **Depends on:** 16.
- **Recommended LLM:** **Opus 4.8** — cross-platform reasoning + targeted fixes.
- **The Prompt:**
  > [STANDARD CONTEXT HEADER]
  > Task: Run a systematic QA matrix: breakpoints (mobile/tablet/desktop/large) × platforms (Web, Windows/macOS desktop, iOS/Android) × directions (LTR/Arabic RTL) × themes (light/dark). For representative screens (login, a master list+form, the Sales Invoice entry, dashboard, a report) verify adaptive nav, master-detail, data-table↔card switch, keyboard/focus on desktop, touch targets on mobile, text scaling, and offline banners/sync badges. Capture issues in `docs/qa/responsive-qa.md` and FIX them (overflow, hit-testing, RTL mirroring, web scroll, desktop window sizing, large-screen max-width). Add golden tests at each breakpoint for the representative screens.
- **Expected artifacts:** `docs/qa/responsive-qa.md`, fixes across `lib/`, breakpoint goldens.
- **Done-when:** No overflow/layout breakage in the matrix; goldens pass; offline UX correct on every platform.

---

### Step 18 — Change-Request Consolidation & Final Review
- **Goal:** Consolidate all CRs, verify full backend coverage, and produce the handoff/readiness report.
- **Depends on:** all.
- **Recommended LLM:** **Opus 4.8** — synthesis + completeness reasoning.
- **The Prompt:**
  > [STANDARD CONTEXT HEADER]
  > Task: Consolidate `docs/change-requests/` into a prioritized index (P0 blockers → P3 nice-to-have), emphasizing **offline-sync CRs** (delta `?updatedSince=`, server `updated_at` in lists, soft-delete tombstones, POST idempotency keys, bulk hydration) and feature gaps (Quotation→SalesOrder conversion, stock-ledger read, trial-balance/P&L/balance-sheet, payment/receipt settlement-allocation, audit-log read). Then run a **completeness audit**: cross-check `docs/feature-inventory.md` against implemented `lib/features/**` — every endpoint has a UI path or a documented reason; every entity has a screen; RBAC gating is applied everywhere. Produce `docs/STATUS.md` (coverage matrix, known gaps, test summary, per-platform run instructions) and `docs/architecture.md` (final layer diagram + reuse map). List anything still stubbed.
- **Expected artifacts:** `docs/change-requests/README.md` (prioritized), `docs/STATUS.md`, `docs/architecture.md`.
- **Done-when:** Coverage matrix shows 100% of endpoints addressed (implemented or CR-tracked); status report is accurate.

---

## Change Request template (`docs/change-requests/_TEMPLATE.md`)

```markdown
# CR-<NNN>: <short title>
- **Status:** Open | In Review | Accepted | Rejected | Implemented
- **Priority:** P0 (blocks frontend) | P1 | P2 | P3
- **Module / Endpoint:** <e.g. transactions / POST /transactions/sales-invoice>
- **Type:** Missing endpoint | Unclear contract | Offline-sync gap | Bug | Enhancement
- **Found in step:** <step #>

## Problem
What the frontend needs and why the current backend can't satisfy it.

## Evidence
File/line references in `algo-backend/models/backend/src/...` and the contract expectation.

## Proposed change
Concrete API shape (method, path, request, response) or behavior change.

## Frontend impact / workaround
What is blocked; the temporary assumption/abstraction used until resolved.
```

---

## LLM routing summary

| Phase | Steps | LLM | Why |
|---|---|---|---|
| Discovery | 0 | Opus | accuracy gates everything |
| Scaffold + Core | 1–8 | Opus | architecture; one wrong decision propagates |
| Widget library | 9 | Opus (+Flash for trivial) | shared API must be right |
| Gold template A | 10 | Opus | copied ~39× |
| Stamp masters | 11 | **Flash** | settled template, high volume |
| Gold template B | 12 | Opus | most complex screen, copied 17× |
| Stamp documents | 13 | Opus (config) + **Flash** (boilerplate) | vouchers vary more than masters |
| Dashboard/shell | 14 | Opus (+Flash cards) | composition |
| Reports | 15 | Opus (framework) + **Flash** (configs) | |
| Polish | 16 | Opus (system) + **Flash** (apply) | |
| QA | 17 | Opus | cross-platform reasoning |
| CR + review | 18 | Opus | synthesis |

**Rule of thumb:** Opus designs the template; Flash stamps it out.

---

## Verification (how to prove the build end-to-end)

1. **Per-step gates:** each step's *Done-when* must pass before the next (the dependency spine is strict — Core 4/5/6/7 gate all features).
2. **Backend up:** run the backend (`E:\work\algo-backend\models\backend`, see its README/`.env`) and point a Flutter flavor's base URL at it.
3. **Auth smoke (Step 8):** real login → token refresh → RBAC-gated menu for a limited role.
4. **Offline loop (Steps 6/10/12):** airplane-mode → create a Brand and a Sales Invoice → restart app (data persists in drift) → reconnect → sync pushes, server ids/voucher numbers adopted, no duplicates (idempotency).
5. **Document correctness (Step 12/13):** a posted Sales Invoice's totals + GL match the backend; financial vouchers balance (Σdr=Σcr).
6. **Coverage (Step 18):** `docs/STATUS.md` maps every endpoint in `docs/feature-inventory.md` to a UI path or a CR.
7. **Automated:** `flutter analyze` clean; `flutter test` (bloc_test + goldens) green; CI workflow passes; goldens cover light/dark × LTR/RTL × breakpoints for representative screens.

## Top risks to watch
- **Offline sync vs server-authoritative posting** — vouchers can't get real numbers/GL offline; the `pendingSync` + id-adoption design (Step 6/12) is the crux. Most P0 CRs live here.
- **Backend not sync-ready** — no delta/idempotency/tombstone support today ⇒ Step 6 must code against abstractions + a full-refresh fallback until CRs land.
- **86 entities of drift schema** — keep migrations regenerated after each stamping wave (Steps 11/13).
- **Decimal discipline** — never `double` for money/qty; mismatched rounding will desync from backend GL.
</content>
</invoke>
