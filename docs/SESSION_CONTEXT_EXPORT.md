# algoERP Frontend — Session Context Export

> Exported 2026-07-11. Purpose: a complete, self-contained record of the architectural
> decisions, work completed, and open forks in this build so any future session (or
> teammate) can resume without re-deriving context.

---

## 1. The pivot: offline-first → online-only

The project started from a 19-step offline-first plan (local drift DB, outbox, sync
engine). Mid-build the direction changed:

- **Decision:** ship a full **online-only** version first — repositories talk to the
  backend directly over Dio. No local DB, no sync, no outbox.
- **Offline is not abandoned — it's parked.** Every data boundary is an **interface**
  (`Repository<E, ID>`) specifically so an offline implementation can be dropped in later
  with **zero rewrites** to features built against it. `lib/core/database/**` (drift
  tables already scaffolded under the old plan) is excluded from `analysis_options.yaml`
  and untouched.
- **Reusability mandate:** the user asked explicitly for reusable code and for task
  groups to be split so mutually-exclusive work can run in parallel, done to a standard
  that "teaches a better way of code implementation."

This produced the **doctrine (R1–R7)** that governs every subsequent decision:

| Rule | Statement |
|---|---|
| R1 | Program to interfaces, not implementations |
| R2 | One generic abstraction, not forty near-duplicates |
| R3 | UI states are sealed and exhaustive (`switch` never needs a default) |
| R4 | Compose behavior with mixins, not inheritance chains |
| R5 | Contract-first, then parallelize — freeze interfaces once, build behind them concurrently |
| R6 | Single source of truth for each API shape (one DTO per wire shape) |
| R7 | Decimal for money/qty, RBAC and adaptive layout by default, never optional |

---

## 2. Work completed, in order

### Steps 0–4 (pre-existing before this session's active work)
Discovery docs, project scaffold (3 flavors, DI bootstrap), Material 3 design system
(`AppTokens`, light/dark, motion, RTL), responsive/adaptive shell (breakpoints,
`AppShell`, go_router `ShellRoute`, data-driven `AppMenu`), and the network layer
(`DioClient` + interceptors, `ApiResponse`/`Paginated` decode, sealed `Failure` +
`safeCall`). All still standing, untouched by this session except where noted below.

### Wave 0 — Contracts & Seams (frozen interfaces)
The "contract-first" half of R5. Everything downstream depends on these staying stable:

- `lib/core/usecase/usecase.dart` — `UseCase<Out, In>` + `NoParams`
- `lib/core/domain/page_query.dart` — `PageQuery`, `SortSpec`, `SortDirection` (pure value objects)
- `lib/core/domain/repository.dart` — `Repository<E, ID>` (list/getById/create/update/delete)
- `lib/core/data/remote_data_source.dart` — `RemoteDataSource` interface + `JsonMap` typedef
- `lib/core/data/mapper.dart` — `Mapper<D, E>` (DTO ↔ Entity)
- `lib/core/bloc/crud_contract.dart` — sealed `CrudState<E>` / `CrudEvent<E, F>`
- `lib/core/auth/permission_contract.dart` — `PermissionService` interface + `RbacMixin`
- `lib/core/widgets/view_state.dart` — sealed `ViewState<T>` (bloc-decoupled UI state)
- `docs/feature-contract.md` — the frozen recipe: "to add a master-CRUD feature, supply
  exactly: DTO+fromJson, Entity, Mapper, resource path+id selector, RBAC module name, form
  field list, DI registration." Also locks field-naming, Decimal↔String, ID=int,
  soft/hard delete, validation body-prefix stripping conventions.
- `docs/backend-suggestions.md` — living log of backend gaps found while building (see §5).

### Track A — Reuse Keystone (generic data + bloc engine) ✅ complete
The **one** generic implementation every feature reuses — this is where R2 is enforced.

- `lib/core/data/remote_data_source_base.dart` — the one HTTP data source, bound to a
  resource path at construction, never subclassed.
- `lib/core/data/remote_repository.dart` — `RemoteRepository<E, ID>`, composes
  `decode`/`encode`/`idOf` closures over the generic data source (kept to 2 generics by
  avoiding a DTO type parameter).
- `lib/core/bloc/crud_bloc.dart` — `CrudBloc<E, ID, F>` (list/search/paginate/mutate,
  in-place list updates on create/update/delete, `mutationFailures` side-channel stream so
  a failed row action doesn't blow away sealed state; delete failure triggers a refresh
  rollback).
- `lib/core/bloc/detail_bloc.dart` — single-entity load/delete, bound to one id at construction.
- `lib/core/bloc/mixins/pagination.dart`, `search_debounce.dart`, `form_mixin.dart`.
- `lib/core/utils/extensions/{build_context_x,format_x,view_state_x}.dart`.
- Tests: `test/core/bloc/crud_bloc_test.dart` — 8 tests (load success/error, loadMore,
  search debounce, create/update/delete, delete-failure-restores).

**Key design resolutions:**
- `CrudBloc` needed **3** generics (`E, ID, F`) because `Repository<E,int>` is not
  assignable to `Repository<E,Object>` — method-parameter contravariance. `RemoteRepository`
  stayed at 2 generics by using closures instead of a DTO type param.
- Dio confirmed as the right HTTP client (native interceptors/refresh already built in
  Step 4; isolated behind `RemoteDataSource` so it's swappable later if ever needed).

### Track B — Identity & Access ✅ complete (spawned as a background agent, Opus)
Full auth stack against the **real, verified** backend contract
(`models/backend/src/core/auth/auth.controller.ts`):

- `lib/features/auth/data/dtos/{auth_user_dto,auth_session_dto}.dart` — hand-written
  (no freezed, so the agent's output was analyzable without running build_runner).
- `lib/features/auth/data/auth_remote_data_source.dart`, `auth_repository_impl.dart`
- `lib/features/auth/domain/{entities/auth_user.dart,auth_repository.dart}`
- `lib/features/auth/presentation/bloc/{auth_bloc,auth_event,auth_state}.dart` — sealed
  `AuthState` (`AuthInitial/AuthLoading/AuthAuthenticated{user,changePassword sub-status}/
  AuthUnauthenticated/AuthFailure{failure,fieldErrors}`); change-password progress is
  carried **on** `AuthAuthenticated` (not a separate top-level state) so it never trips
  the router's auth redirect.
- `lib/features/auth/presentation/pages/login_page.dart` (adaptive, theme/RTL-aware)
  and `presentation/widgets/change_password_dialog.dart`.
- `lib/core/auth/permission_service.dart` — `FailOpenPermissionService` (returns `true`
  always — interim per **BE-001**, real gate is the server's 403 until a permission-read
  endpoint exists).
- `lib/core/auth/permission_gate.dart` — `PermissionGate` widget.
- Tests: 12 (`test/features/auth/auth_bloc_test.dart`,
  `test/core/auth/{permission_service_test,permission_gate_test}.dart`).

### Track C — Reusable Widget Library ✅ complete (spawned as a background agent, Sonnet)
Token-only, theme/RTL-aware primitives — no hardcoded colors/sizes anywhere:

- `lib/core/widgets/async_state_view.dart` + `states/{loading,empty,error}_state.dart`
  — renders over the Wave-0 `ViewState<T>`.
- `lib/core/widgets/fields/` — `app_{text,number,decimal,currency,date,switch,dropdown}_field.dart`.
- `lib/core/widgets/chips/status_chip.dart`, `dialogs/confirm_dialog.dart`,
  `filters/filter_bar.dart`, `lookup/fk_lookup_field.dart` (debounced FK picker),
  `data_display/adaptive_entity_list.dart` (table ↔ cards by breakpoint),
  `data_display/line_item_grid.dart` (editable voucher line rows).
- `lib/core/widgets/gallery/widget_gallery_page.dart` — light/dark × LTR/RTL showcase.
- `docs/widget-catalog.md` — props/RTL/theming notes + usage snippet per widget.
- Tests: 14 (`test/core/widgets/*_test.dart`).

### Central wiring (done by the orchestrating session after both tracks landed)
Both agents were explicitly forbidden from touching shared files (to stay parallel-safe
without git worktree isolation) and instead returned "WIRING REPORTS." Applied centrally:

- **`lib/core/navigation/app_router.dart`** — converted the static `appRouter` into
  `createAppRouter(AuthBloc)`. Added chrome-less `/login` and `/403` routes outside the
  `ShellRoute`. Implemented `appRouterRedirect` (waits during `AuthInitial`/`AuthLoading`;
  sends unauthenticated → `/login`; bounces authenticated-at-`/login` → `/dashboard`; `/403`
  is a destination screens navigate to on `ForbiddenFailure`, never synthesized by the
  guard itself). Added `GoRouterRefreshStream` (Stream→Listenable adapter; go_router
  doesn't ship one) wired as `refreshListenable` so auth transitions re-run the guard.
  Folded the widget-gallery route into the existing theme-preview special-case `switch`.
- **`lib/app.dart`** — top-level `MultiBlocProvider` (`ThemeCubit` + `AuthBloc`, dispatching
  `AuthStarted` on creation). Router is built **once** inside a `State` (`_AppViewState`),
  not inside `build()`, so theme-driven rebuilds never recreate the `GoRouter` or leak the
  refresh-stream subscription — the one real integration trap Track B's report flagged.
- **`lib/core/navigation/menu_model.dart`** — added the "Widget gallery" dev nav entry.
- **DI regeneration** — `dart run build_runner build --delete-conflicting-outputs`,
  confirmed all four new bindings registered in `injection.config.dart`
  (`AuthRemoteDataSource`, `AuthRepositoryImpl→AuthRepository`, `AuthBloc`,
  `FailOpenPermissionService→PermissionService`).
- One post-merge lint (80-col) fixed in `app_router.dart`.

**Verification after merge:** `flutter analyze` → **No issues found.**
`flutter test` → **54/54 passing.**

---

## 3. Current repo state (verified 2026-07-11)

```
flutter analyze   → No issues found!
flutter test      → 54/54 passing
```

Task tracker status:
- ✅ Step 2 (design system), Step 3 (responsive shell), Step 4 (network layer)
- ✅ Wave 0 (contracts & seams)
- ✅ Track A (reuse keystone), Track B (identity & access), Track C (widget library)
- ✅ EMR vertical slice — manifest model (`FieldType`/`FieldSpec`/`EntityManifest`,
  deliberately minimal), `MasterListSurface`, Brand list binding
  (`lib/features/inventory_brand/**`) wired to `/inventory/brand`. Detail/form Surfaces,
  command palette, Decimal Line Engine, `ClientQuery` remain unbuilt by design — see the
  checkpoint below.
- `docs/BUILD_TASKS_V2.md` §7/§8 updated in place with exact `[x]`/`[~]`/`[ ]` status per
  sub-item, so it stays the authoritative source of what's done vs deferred.

### Decision checkpoint (live, unresolved)

Now that `/inventory/brand`'s list renders through `MasterListSurface`, stop and decide
with the user: extend EMR (build `MasterDetailSurface`/`MasterFormSurface`, add
create/edit/delete to Brand, then register more masters) — or fall back to hand-written
feature packages (v1) if the manifest pattern felt more awkward than the code it
replaced. Do not silently keep building more EMR machinery without this checkpoint.

---

## 4. ⚠️ Fork (RESOLVED 2026-07-11): two competing plans for what comes next

Resolution: neither v1 nor v2 wholesale — the user chose a **vertical slice** of v2
(manifest model + `MasterListSurface` + Brand list only) to validate the pattern on real
data before committing further either way. See the live checkpoint in §3 above.

Original fork, kept for context: this is the most important thing for a future session to
see immediately.

The repo contains **two planning documents that disagree on strategy from this point
forward**:

- **`docs/BUILD_TASKS.md` (v1, original plan)** — the plan actively executed through
  Wave 0/Track A/B/C above. Its next step is **Wave 2: Gold Template A** — build Brand as
  a full hand-written feature package (DTO/Entity/Mapper/Bloc wiring/pages), then in Wave
  3 **stamp** that same package ~39 times across master entities and ~17 times across
  voucher types.
- **`docs/BUILD_TASKS_V2.md` (manifest-driven plan, present in the repo but not yet
  executed — no `lib/core/manifest/`, `lib/core/surfaces/`, or `docs/manifest-spec.md`
  exist)** — proposes replacing "stamp 40 feature packages" with an **Entity Manifest
  Runtime (EMR)**: entities become typed manifest declarations consumed by shared
  `MasterListSurface`/`MasterDetailSurface`/`MasterFormSurface`, vouchers become
  `VoucherBlueprint`s consumed by a `DocumentSurface`. It also proposes a command palette,
  a pure-Dart Decimal Line Engine, a `ClientQuery` adapter (client-side search/sort/filter
  until BE-002–004 land), and an idempotency-key write shield (BE-005). It re-labels
  Track A/B/C as its own "Wave A0/A1/A2" and inserts a new "Wave A3 (EMR core)" before
  anything resembling the old Wave 2.

**Neither plan has been reconciled with the other yet, and no EMR code exists.** v2's own
"Wave A0" checklist (documenting Track A's intentional deviations in `feature-contract.md`,
a `RepoBinding`/`registerRemoteRepository` DI helper, a `ClientQuery` adapter, an
idempotency-key interceptor) has **not been done** — Track A as actually built satisfies
v1's Wave 0/Track A scope, not v2's expanded A0 scope.

**Decision needed before Wave 2 starts:** stamp Brand as a hand-written feature package
(v1), or build the EMR core first and express Brand as its first manifest (v2)? This
determines the shape of every master/voucher after it — it is not a decision to make
implicitly by just picking one and starting to code.

---

## 5. Backend gaps log (`docs/backend-suggestions.md`)

Verified against actual backend source, not assumed:

| ID | Priority | Gap | Interim workaround |
|---|---|---|---|
| BE-001 | P0 | No endpoint to read a role's permission matrix | `PermissionService` fails **open**; real gate is the server's 403 |
| BE-002/003/004 | P1 | No search/filter/sort on list endpoints | Params still forwarded (forward-compat); v2 plan proposes a client-side `ClientQuery` adapter as a fuller fix |
| BE-005 | P1 | No POST idempotency keys | Don't auto-retry mutating verbs; v2 proposes a client-generated `Idempotency-Key` header (harmless until backend honors it) |
| BE-006 | P2 | No active FY in session | — |
| BE-007 | P2 | List envelope not fully standardized | — |
| BE-008 | P2 | No lightweight FK-lookup projection endpoint | FK fields hit the full list endpoint and project client-side |

## 6. Deferred polish (non-blocking, saved to memory)

1. **l10n auth strings** — login/change-password page text and some widget defaults are
   English literals; `.arb` files (`app_en.arb`/`app_ar.arb`) currently only define
   `appTitle`, `loading`, `error`, `retry`, `empty`. Needs new `auth*` keys + regen.
2. **`AppTokens` neutral-icon color** — `EmptyState`/`ErrorState` fall back to
   `colorScheme.outline` / `semanticColors.danger` because no dedicated neutral/muted icon
   token exists yet.

---

## 7. Model-selection guidance established this session

- **Opus** for architecture/contract decisions with high blast radius (Wave 0 seams,
  generic bloc/repository design, auth/security-sensitive work) — mistakes here get
  copied everywhere downstream.
- **Sonnet** for mechanical, well-specified, pattern-following work once a contract exists
  (Track C's widget library against `feature-contract.md`; later, stamping entities against
  a proven gold template).
- Parallel agents were scoped to **disjoint folders** with a **shared-file blocklist**
  (`pubspec.yaml`, router, menu model, DI files, `analysis_options.yaml`) and told to
  return a **WIRING REPORT** instead of touching shared files directly — the pattern that
  made two-agent parallelism safe without git worktree isolation.

---

## 8. Suggested immediate next step

See the decision checkpoint in §3: run the app against Brand's list to judge the pattern
on real data, then decide with the user whether to extend EMR (detail/form Surfaces, more
masters) or fall back to v1. Do not resume building EMR machinery without that check-in.
