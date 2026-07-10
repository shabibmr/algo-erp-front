# Feature Contract

**The deal:** the core layer (Waves 0–2) provides all the machinery — repository,
data source, bloc, widgets. To add a feature you supply only the parts that are genuinely
*unique to that entity*. If you find yourself writing a new bloc, a new repository class, or a
new list widget, stop — that logic belongs in core, not the feature.

This is the frozen output of **Wave 0**. Tracks A (engine), B (auth), and C (widgets) each build
against these interfaces without needing anything from each other.

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

1. **DTO** — a `freezed` + `json_serializable` class mirroring the wire **exactly**
   (`@JsonKey(name: 'Brand_Name')`, `is_active`, …) with `fromJson`/`toJson`.
2. **Entity** — a clean domain class (nice names, `Decimal` for money, real enums).
3. **Mapper** — implement `Mapper<Dto, Entity>` (`toEntity`/`toDto`).
4. **Resource path + id selector** — e.g. `/inventory/brand` and `(e) => e.id`.
5. **RBAC module name** — the PascalCase string (e.g. `Brand`) for gating.
6. **Form field list** — which typed fields the create/edit form renders.
7. **DI registration** — bind the entity's `Repository<E, ID>` to the generic
   `RemoteRepository` with the path + mapper + DTO codec.

Everything else — list/detail/form pages, pagination, search debounce, error handling,
sync badges' absence, RBAC-gated buttons — comes from core. **No new bloc. No new repository.
No new primitives.**

---

## Locked conventions (verified against backend source, 2026-07-11)

- **Field naming.** DTOs keep the backend's inconsistent casing via `@JsonKey`; mappers produce
  clean entity names. The wire shape lives only in the DTO.
- **Decimal.** Backend serializes Prisma `Decimal` as a JSON **string**. DTOs type such fields as
  `String`; the mapper converts to `package:decimal` `Decimal`. **Never `double`** for money/qty.
- **IDs.** Integer primary keys → `ID = int`.
- **Ids/paths.** Resource paths are singular where the backend is (`/inventory/brand`); confirm each
  against `docs/feature-inventory.md`.
- **Soft vs hard delete.** Most entities soft-delete via `is_active`; Brand/Category/AccountGroup
  **hard-delete**. The entity declares which; `Repository.delete` hides the difference.
- **Validation errors → form fields.** `Failure.validation.fieldErrors[].field` arrives as a Zod
  path **prefixed with `body`** (e.g. `body.Brand_Name`). The `FormMixin` (Track A) **strips the
  leading `body`/`query`/`params` segment** before binding the error to a field.
- **List capabilities.** Server honours `page`/`limit` only today; `search`/`filters`/`sort` in
  `PageQuery` are forwarded but currently no-ops server-side (BE-002/003/004). Features are written
  as if they work; enabling them later is a data-source change, not a feature change.
- **RBAC.** No permission-read endpoint yet (BE-001) → `PermissionService` fails open for now.
  Still gate every action via `PermissionGate`/`RbacMixin` so it "just works" once BE-001 lands.

---

## Non-negotiables every feature inherits
- Clean Architecture layering: `domain` → `data` → `presentation`, dependencies point inward.
- All state via `flutter_bloc`; states are sealed and exhaustively handled.
- Adaptive by default (list ↔ master-detail, table ↔ cards) using core layout primitives.
- Tokens only — no hardcoded colors/sizes. RTL-correct. en + ar.
- Program to `Repository<E, ID>`, never to a concrete data source — this is what keeps
  online-now / offline-later a drop-in.
