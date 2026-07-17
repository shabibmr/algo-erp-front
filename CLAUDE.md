# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

`algo_erp_front` is the Flutter client for algoERP. The backend it talks to lives outside this
directory, at `../models/backend` (TypeScript + Express 5 + Prisma + MySQL).

---

## Commands

The Flutter SDK on this machine is at `E:/flutter/bin/flutter`. The `Makefile` targets call a bare
`flutter`, so they only work if the SDK is on `PATH`.

```bash
flutter pub get                                            # make bootstrap
dart run build_runner build --delete-conflicting-outputs   # make gen   (freezed, injectable)
dart run build_runner watch  --delete-conflicting-outputs   # make gen-watch
flutter analyze                                            # make analyze
dart format .
flutter test                                               # make test
flutter clean
```

Run a single test file, or a single test/group by name:

```bash
flutter test test/features/auth/auth_bloc_test.dart
flutter test test/features/auth/auth_bloc_test.dart --plain-name 'AuthStarted'
```

Run the app — three flavor entrypoints, each with its own `API_BASE_URL` baked in as a default, so
`make run-dev` needs no override:

```bash
make run-dev        # flutter run -t lib/main_dev.dart      --dart-define=API_BASE_URL=http://localhost:5000
make run-staging    # flutter run -t lib/main_staging.dart  --dart-define=API_BASE_URL=https://staging-api.algoerp.internal
make run-prod       # flutter run -t lib/main_prod.dart     --dart-define=API_BASE_URL=https://api.algoerp.com
# add -d chrome | -d windows | -d android | ... to pick a device
```

**CI** (`.github/workflows/ci.yml`, Flutter 3.44.0) runs exactly this sequence on push/PR to `main`:
`flutter pub get` → `build_runner build` → `dart format --output=none --set-exit-if-changed .` →
`flutter analyze` → `flutter test`. The format gate is strict, so run `dart format .` before
committing. Lints are `very_good_analysis` (much stricter than `flutter_lints`); `lib/core/database/**`
and all generated files are excluded from analysis.

---

## Architecture: the manifest-driven master engine

This is **not** a conventional feature-per-bloc Flutter app, and writing it as one is the most likely
way to go wrong here. The core layer owns all the machinery — repository, data source, bloc, list and
form screens. A feature **declares** an entity; core **renders** it. Nearly every feature under
`lib/features/` follows this and contains **zero bloc, repository, or list-widget code**.

The engine is three pieces:

| Piece | File | Role |
|---|---|---|
| `EntityManifest<E>` | `lib/core/manifest/entity_manifest.dart` | The typed declaration of an entity: label, `rbacModule`, `resourcePath`, list columns, form fields, capability flags |
| The Surfaces | `lib/core/surfaces/master_list_surface.dart`, `master_form_surface.dart` | Generic list + create/edit screens that render any manifest. `FieldRenderer` (`core/manifest/field_renderer.dart`) is the one `switch` mapping a `FormFieldSpec` to a widget |
| `CrudBloc<E, ID, F>` | `lib/core/bloc/crud_bloc.dart` | One generic bloc: load, refresh, infinite scroll, debounced search, filter, create/update/delete against any `Repository<E, ID>` |

Everything else in `core/` supports those: `core/data/` (one `RemoteDataSourceBase`, one
`RemoteRepository` — never subclassed), `core/domain/repository.dart` (the `Repository<E, ID>`
interface every feature programs against), `core/network/` (Dio client + auth/tenant/request-id
interceptors), `core/error/` (freezed `Failure` union, `Result<T> = Either<Failure, T>` via fpdart),
`core/auth/` (RBAC), `core/navigation/` (go_router + adaptive shell), `core/theme/` (`AppTokens`),
`core/widgets/` (the design system — see `docs/widget-catalog.md`).

State management is **flutter_bloc**, not Riverpod. DI is `get_it` + `injectable`, but only a handful
of things are in the container (`DioClient`, `AuthBloc`, `ThemeCubit`, `TokenStorage`,
`TenantContext`, `PermissionService`). Master repositories and blocs are deliberately **plain factory
functions**, not `@injectable` — see `core/di/repo_binding.dart`.

`lib/features/auth/` is the one feature with hand-written bloc/repository code, because it predates
and bootstraps the engine. Do not treat it as the template for a master.

---

## Adding a master entity

The canonical recipe is `docs/manifest-spec.md` ("the 7-file checklist"). Reference implementations:
`lib/features/inventory_brand/` (flat entity) and `lib/features/employee_designation/` (the FK case).

Create `lib/features/<module>_<entity>/` with seven files:

1. `domain/<entity>.dart` — `Equatable` entity + `copyWith`
2. `data/<entity>_dto.dart` — the wire shape, in the backend's exact casing (`dept_code`, `Brand_Name`)
3. `data/<entity>_mapper.dart` — `implements Mapper<Dto, Entity>`
4. `<entity>_manifest.dart` — the `EntityManifest<E>` (note: feature root, not a subfolder)
5. `<entity>_di.dart` — two plain factory functions, `create<E>Repository` / `create<E>CrudBloc`
6. `presentation/<entity>_list_page.dart` — provides the `CrudBloc`, renders `MasterListSurface<E>`
7. `presentation/<entity>_form_page.dart` — provides the `Repository`, renders `MasterFormSurface<E, ID>`

Then three registration edits in shared files: two routes (`/<path>/new` and `/<path>/:id`) plus one
`switch` arm for the list page in `lib/core/navigation/app_router.dart`, and one `MenuItemModel` in
`lib/core/navigation/menu_model.dart`.

Rules that are easy to get wrong:

- **`rbacModule` is not the entity name.** Brand, UOM and Category all gate on `'Inventory'`;
  Department and Designation on `'Employee'`; Organization entities gate per-entity. Verify against
  the backend route files.
- **Partial CRUD is a flag, not a new screen.** If the backend has no PUT or no DELETE, set
  `supportsUpdate: false` / `supportsDelete: false` on the manifest. `MasterFormSurface` then renders
  read-only, hides Save/Delete, and refuses the action. Worked examples: `itemPropertyManifest`,
  `financialYearManifest`.
- **`hardDelete: true` only if the table genuinely has no `is_active` column** — check the schema.
- **Nullable fields in `copyWith` need a sentinel default.** `?? this.field` can never null out a
  value once set.
- **`toJson()` must not send `id`** or any server-generated field.
- **FK fields** need the three closures (`fkSearch` / `fkDisplayOf` / `fkResolveById`), and the
  related repository must be built once at module level, not per keystroke.
- **When an entity doesn't fit** (compound key, self-FK tree, binary field, missing list endpoint):
  **do not fork the Surfaces.** Record it in `docs/manifest-exceptions.md` with the reason. About 16
  entities are deferred there already.

---

## Backend contract

Full detail in `docs/api-contract.md`; live gaps and their status in `docs/backend-suggestions.md`
(a living log — append a `BE-NNN` entry when you hit a new backend limitation).

- **Port.** The backend listens on **5000** (`models/backend/.env`), which is what the dev flavor
  targets. Dev seed login is `brand.tester` / `BrandTest123!`.
- **No `/api/v1` prefix.** Routers mount at the root: `/auth`, `/inventory`, `/organization`,
  `/accounts`, `/employee`, `/transactions`, `/reports`.
- **Envelope.** `{ success, message?, data?, error?: { message, code?, details? }, requestId? }`.
  Lists put `{ items, meta: { total, page, limit, totalPages } }` in `data`. `error.code` is declared
  but never populated — don't branch on it.
- **Auth.** JWT bearer. `AuthInterceptor` attaches the token and, on a 401, performs exactly one
  `POST /auth/refresh` (concurrent 401s share it), replaying the original request on a bare Dio with
  no interceptors. Tokens live in `flutter_secure_storage`.
- **Query params: unknown keys are not inert.** Only `page`, `limit`, `search`, `sortBy`, `sortOrder`
  are reserved; every *other* query param is treated as a Prisma `where` filter and can 500 the
  request. Sending `sortDir` instead of `sortOrder` was a real bug here.
- **Money.** Prisma `Decimal` serializes as a JSON **string**, but legacy `Float` columns come back as
  JSON numbers. Use `package:decimal` and decode defensively — **never `double`** for money or
  quantity.
- **Validation errors.** Zod paths arrive prefixed with `body.` / `query.` / `params.`. `FormMixin`
  strips the first segment; a `FormFieldSpec`'s `wireKey` is what matches the error back to the widget.
- **Tenancy.** `X-Company-Id` / `X-Branch-Id` are sent by `TenantInterceptor`, but the JWT's claims
  always win server-side.
- **Idempotency** exists server-side but is deliberately **not used** by the client (the middleware is
  in-memory and not scoped per-user). POST/PUT auto-retry stays disabled. See BE-005.

---

## The docs folder — what to trust

**Authoritative:**
- `docs/STATUS.md` — the living status board: which entities are shipped, partial, deferred, or
  parked. Check here first to see what already exists.
- `docs/manifest-spec.md` — the recipe for adding an entity. Start here to build one.
- `docs/bloc-migration-checklist.md` — per-package work queue to retire hand-written master List/FormBlocs onto EMR.
- `docs/manifest-exceptions.md` — entities that don't fit, and why.
- `docs/api-contract.md` — the backend contract.
- `docs/backend-suggestions.md` — living log of backend gaps (BE-001…BE-008) and their status.
- `docs/widget-catalog.md` — the core widget library.
- `docs/BUILD_TASKS_V2.md` — the live execution plan, including the stack boundary (free/first-party
  only: no paid UI kits, no commercial chart/PDF engines; charts via `CustomPainter`, CSV always).
- `docs/UI_DESIGN_PLAN.md` — the "Ledger & Linen" design system.
- `docs/feature-contract.md` — the interfaces core guarantees and the conventions every feature
  inherits. For the step-by-step mechanics of adding an entity, `manifest-spec.md` supersedes it.

**Historical — do not follow:** `PROMPT_EXECUTION_PLAN.md` and `docs/BUILD_TASKS.md` (both superseded
by `BUILD_TASKS_V2.md`), `docs/offline-sync-readiness.md`, and `docs/change-requests/*`. These all
assume the **offline-first** architecture, which was reversed by an online-only pivot. Offline is
parked, not abandoned: `lib/core/database/**` still exists but is unwired and excluded from analysis.
Don't build against it.

---

## Conventions and anti-patterns

Doctrine, from `docs/SESSION_CONTEXT_EXPORT.md`: program to interfaces; one generic abstraction rather
than forty near-duplicates; sealed, exhaustively-handled UI states; compose with mixins, not
inheritance chains; `Decimal` for money; RBAC and adaptive layout by default, never optional.

Do not:
- **Write a per-feature bloc, repository, or list widget.** If you're reaching for one, the logic
  belongs in `core/` — or the entity belongs in `manifest-exceptions.md`.
- **Hardcode a color, spacing, or radius.** Everything comes from `context.tokens` (`AppTokens`, a
  `ThemeExtension`). The seed color is a Gulf lagoon teal, deliberately not Material blue.
- **Use `double` for money or quantity.** Use `Decimal`.
- **Register a master repository as `@injectable`.** They're plain factory functions on purpose.
- **Invent a backend API.** File a `BE-NNN` entry in `docs/backend-suggestions.md` and adapt around it.

Tests mirror `lib/` under `test/`, using `bloc_test` + `mocktail` (no mockito/codegen mocks).
`test/flutter_test_config.dart` is picked up automatically and disables Google Fonts runtime fetching.
