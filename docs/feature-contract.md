# Feature Contract

**The deal:** the core layer (Waves 0–2) provides all the machinery — repository,
data source, bloc, widgets. To add a feature you supply only the parts that are genuinely
*unique to that entity*. If you find yourself writing a new bloc, a new repository class, or a
new list widget, stop — that logic belongs in core, not the feature.

This is the frozen output of **Wave 0**. Tracks A (engine), B (auth), and C (widgets) each build
against these interfaces without needing anything from each other.

> **Scope note.** This document defines the *contract* — the interfaces core guarantees and the
> conventions every feature inherits. The **operative step-by-step recipe** for adding a master entity
> is `docs/manifest-spec.md` (the 7-file checklist), which postdates this file and supersedes the
> sketch in "To add a master-CRUD feature" below. Where the two differ on mechanics, follow
> `manifest-spec.md`. The conventions and non-negotiables here still hold.

---

## The frozen interfaces (Wave 0)

| Contract | File | Role |
|----------|------|------|
| `UseCase<Out, In>`, `NoParams` | `core/usecase/usecase.dart` | One unit of business logic → `Result<Out>` |
| `PageQuery`, `SortSpec` | `core/domain/page_query.dart` | The one list-query shape (page/limit/search/filters/sort) |
| `Repository<E, ID>` | `core/domain/repository.dart` | **The** CRUD contract features depend on |
| `RemoteDataSource`, `JsonMap` | `core/data/remote_data_source.dart` | Dumb HTTP/JSON transport over one resource |
| `Mapper<D, E>` | `core/data/mapper.dart` | DTO ↔ entity translation (single source of truth) |
| `CrudState<E>`, `CrudEvent<E, F>` | `core/bloc/crud_contract.dart` | Sealed list state + events |
| `PermissionService`, `RbacMixin`, `PermissionAction` | `core/auth/permission_contract.dart` | RBAC gating |
| `ViewState<T>` | `core/widgets/view_state.dart` | loading/empty/data/error for `AsyncStateView` |

Existing (Steps 0–4): `Result<T>`/`safeCall` (`core/error/safe_call.dart`),
`Failure` (`core/error/failure.dart`), `Paginated<T>`/`PaginationMeta`
(`core/network/paginated.dart`), `DioClient`, `TenantContext`.

---

## To add a master-CRUD feature, supply exactly:

1. **DTO** — a class mirroring the wire **exactly** (`Brand_Name`, `dept_code`, `is_active`, …) with
   hand-written `fromJson`/`toJson`. In practice these are plain `Equatable` classes, not `freezed` +
   `json_serializable` — the codecs are short enough that codegen earns nothing. `toJson()` never
   sends `id` or any server-generated field.
2. **Entity** — a clean domain class (nice names, `Decimal` for money, real enums). Nullable fields in
   `copyWith` need a **sentinel default**; `?? this.field` can never null out a value once set.
3. **Mapper** — implement `Mapper<Dto, Entity>` (`toEntity`/`toDto`).
4. **Resource path + id selector** — e.g. `/inventory/brand` and `(e) => e.id`.
5. **RBAC module name** — the backend's `authorize()` string, which is **not always the entity name**.
   Brand/Category/UOM gate on the coarse `'Inventory'`; Department/Designation on `'Employee'`;
   Organization entities gate per-entity (`'Branch'`, `'Currency'`, …). Verify against the route file,
   don't infer it from the entity.
6. **Form field list** — which typed fields the create/edit form renders. Each carries a `wireKey`
   (the backend's Zod key) so server validation errors bind back to the right widget.
7. **DI registration** — bind the entity's `Repository<E, ID>` to the generic
   `RemoteRepository` with the path + mapper + DTO codec. These are plain factory functions
   (`create<E>Repository` / `create<E>CrudBloc`), deliberately **not** `@injectable` — see
   `core/di/repo_binding.dart`.

Everything else — list/detail/form pages, pagination, search debounce, error handling,
RBAC-gated buttons — comes from core. **No new bloc. No new repository. No new primitives.**

---

## Locked conventions (verified against backend source, 2026-07-12)

- **Field naming.** DTOs keep the backend's inconsistent casing verbatim in their `fromJson`/`toJson`;
  mappers produce clean entity names. The wire shape lives only in the DTO.
- **Decimal.** Backend serializes Prisma `Decimal` as a JSON **string** — but legacy `Float` columns
  come back as JSON **numbers**, and `ledger_master.Opening_Balance` is stored as a string. So there
  is no single uniform numeric wire type: **decode defensively per field** (accept both), convert to
  `package:decimal` `Decimal` in the mapper. **Never `double`** for money/qty.
- **IDs.** Integer primary keys → `ID = int`.
- **Ids/paths.** Resource paths are singular where the backend is (`/inventory/brand`); confirm each
  against `docs/feature-inventory.md`.
- **Soft vs hard delete.** Most entities soft-delete via `is_active`; Brand/Category/AccountGroup
  **hard-delete**. The entity declares which; `Repository.delete` hides the difference.
- **Validation errors → form fields.** `Failure.validation.fieldErrors[].field` arrives as a Zod
  path **prefixed with `body`** (e.g. `body.Brand_Name`). The `FormMixin` (Track A) **strips the
  leading `body`/`query`/`params` segment** before binding the error to a field.
- **List capabilities.** `page`/`limit`/`search`/`filters`/`sort` are **all honoured server-side**
  (BE-002/003/004 shipped). ⚠️ **Unknown query params are not inert:** only `page`, `limit`, `search`,
  `sortBy`, `sortOrder` are reserved — every *other* param is treated as a `where` filter and, on a
  repo with no `filterFields` whitelist, reaches Prisma and can 500. Send only params the server
  reads. (Sending `sortDir` instead of `sortOrder` was a real bug.)
- **RBAC.** `GET /auth/permissions` exists (BE-001 shipped). `MatrixPermissionService` **fails
  closed** — an unknown module/action is denied, mirroring the server, which treats a missing
  `user_access_permissions` row as all-false. Gate every action via `PermissionGate`/`RbacMixin`.
- **Partial CRUD is a flag, not a new screen.** When the backend has no working `PUT`/`DELETE`, set
  `supportsUpdate: false` / `supportsDelete: false` on the `EntityManifest`. `MasterFormSurface` then
  renders read-only and refuses the action. Do **not** fork a bespoke surface.
- **When an entity doesn't fit** (compound key, self-FK tree, binary field, missing list endpoint):
  record it in `docs/manifest-exceptions.md` with the reason. The Surfaces stay generic; exceptions
  get named, not silently worked around.

---

## Non-negotiables every feature inherits
- Clean Architecture layering: `domain` → `data` → `presentation`, dependencies point inward.
- All state via `flutter_bloc`; states are sealed and exhaustively handled.
- Adaptive by default (list ↔ master-detail, table ↔ cards) using core layout primitives.
- Tokens only — no hardcoded colors/sizes. RTL-correct. en + ar.
- Program to `Repository<E, ID>`, never to a concrete data source — this is what keeps
  online-now / offline-later a drop-in.
