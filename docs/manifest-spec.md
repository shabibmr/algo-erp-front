# EMR manifest recipe

> Written after Brand (full CRUD), Department, and Designation (the FK hard
> case) all worked end to end — this is the *mined* recipe, not a
> speculative one. Update it if a future master breaks the pattern; when
> that happens, note the exception here rather than forking a Surface.

## The 7-file checklist

For a flat master with no foreign keys (Brand's shape, Department's shape):

1. **`domain/<entity>.dart`** — the clean entity (`Equatable`, `copyWith`).
   Any **nullable** field's `copyWith` param must use a sentinel default,
   not `?? this.field` — `?? this.field` can never null out a value once
   set. See `Brand.copyWith`:
   ```dart
   const _unset = Object();
   Brand copyWith({int? id, String? name, Object? description = _unset}) =>
       Brand(
         id: id ?? this.id,
         name: name ?? this.name,
         description:
             identical(description, _unset) ? this.description : description as String?,
       );
   ```
2. **`data/<entity>_dto.dart`** — wire shape, backend's exact field casing
   preserved (`fromJson`/`toJson`). `toJson()` never sends `id` or
   server-generated fields.
3. **`data/<entity>_mapper.dart`** — `implements Mapper<Dto, Entity>` with
   `toEntity`/`toDto`.
4. **`<entity>_manifest.dart`** — `EntityManifest<E>` with:
   - `listColumns` (display-only `FieldSpec<E>`)
   - `formFields` (editable `FormFieldSpec<E>`, each with a `wireKey`
     matching the DTO's JSON key so server validation errors land on the
     right field)
   - `emptyEntity` (required whenever `formFields` is non-empty — the blank
     draft for create mode)
   - `hardDelete: true` only if the backend table has no `is_active` column
     (verify against the schema, don't guess — Brand hard-deletes,
     Department/Designation soft-delete)
   - `supportsUpdate: false` when the backend has **no working `PUT`** for
     this entity (defaults `true`). Edit mode becomes read-only: neutral
     banner ("This entity cannot be edited."), disabled fields, no Save;
     `_submit` also no-ops on update. Create mode is unaffected. Worked
     example: `itemPropertyManifest` (`/inventory/property`).
   - `supportsDelete: false` when the backend has **no working `DELETE`**
     (defaults `true`). Hides Delete in edit mode and no-ops `_delete`.
     Worked example: `financialYearManifest` (`/organization/fy`).
   - Set both to `false` for create-only entities (list + create, view-only
     edit). Do **not** invent a separate surface — these flags are the
     partial-CRUD recipe (see `docs/manifest-exceptions.md`).
   - `rbacModule` — the backend's coarse `authorize()` module string, which
     is **not always the entity name** (Brand/Department/Designation all
     gate on their parent module — `'Inventory'`/`'Employee'` — not a
     per-entity string). Verify against the backend routes, don't guess.
5. **`<entity>_di.dart`** — two plain functions, `create<Entity>Repository`
   and `create<Entity>CrudBloc`, built on `buildRepository` (see
   `lib/core/di/repo_binding.dart`):
   ```dart
   RemoteRepository<Entity, int> createEntityRepository(DioClient client) =>
       buildRepository<Entity, int>(
         client: client,
         resourcePath: entityManifest.resourcePath,
         decode: (json) => _mapper.toEntity(EntityDto.fromJson(json)),
         encode: (e) => _mapper.toDto(e).toJson(),
         idOf: (e) => e.id,
       );
   ```
   Still plain functions, not `@injectable` — no DI registry exists yet and
   none is needed at this scale.
6. **`presentation/<entity>_list_page.dart`** — `BlocProvider<CrudBloc>` +
   `MasterListSurface<E>` with `onCreate`/`onTap` pushing the two form
   routes. Copy `department_list_page.dart` (or `brand_list_page.dart`)
   verbatim and rename.
7. **`presentation/<entity>_form_page.dart`** — `RepositoryProvider` + (edit
   mode only) `BlocProvider<DetailBloc>` + `MasterFormSurface<E, ID>`.
   Copy `department_form_page.dart` (or `brand_form_page.dart`) verbatim
   and rename. Title create as `New ${label}`; for edit mode use
   `Edit ${label}` when `manifest.supportsUpdate`, otherwise
   `View ${label}` (read-only detail).

Plus **2 router entries** (`/<path>/new`, `/<path>/:id`) added directly to
`ShellRoute.routes` in `app_router.dart` (not through the `AppMenu.allItems`
loop — those are menu items, not routes), and one **menu item** in
`menu_model.dart` if the entity should appear in navigation.

## Adding a foreign-key field

Use `FieldType.fk` on a `FormFieldSpec`. Requires three closures — see
`designation_manifest.dart` for the worked example (`Designation.departmentId`
→ `Department`):

- `fkSearch: (query) => relatedRepository.list(PageQuery(search: query))...items`
- `fkDisplayOf: (item) => (item as Related).displayField`
- `fkResolveById: (id) => relatedRepository.getById(id as int)...` — seeds
  the picker's label in edit mode, since the entity only stores the raw id.

The related repository is built **once** (module-level `final`, lazily
initialized via `getIt<DioClient>()`) and closed over by all three closures
— constructing a fresh `RemoteRepository` per keystroke would be wasteful.
See `designation_manifest.dart`'s `_departmentRepository`.

`setValue` for an `fk` field receives the picker's **selected object**, not
the raw id — extract the id at that boundary:
```dart
setValue: (d, v) => d.copyWith(departmentId: (v! as Department).id),
```

### Cross-module FKs

Same mechanics as same-module FKs (Designation → Department). Extra rules:

1. The **target** feature package exposes `createXRepository(DioClient)` from
   its `*_di.dart` (domain/data only — never import the target’s presentation).
2. The **consumer** manifest owns a module-level lazy repo singleton and closes
   over it in `fkSearch` / `fkDisplayOf` / `fkResolveById`.
3. RBAC for the screen stays the **consumer** entity’s `rbacModule` (e.g. Ledger
   gates on `Accounts` even when picking an AddressBook contact).
4. If the target is not registered yet, **stop** and list the entity in
   `manifest-exceptions.md` — do not stub fake pickers.

Worked same-module example: `designation_manifest.dart`.  
Worked cross-module examples: `ledger_manifest.dart` (→ AddressBook), `inventory_item_manifest.dart` (→ Ledger, four independent FKs reusing one ledger repository).

## What's still deliberately out of scope

- **`FieldType.selfFk`** — **shipped** (first consumer: InventoryGroup parent).
  Uses the same lookup picker as `fk`; `MasterFormSurface` excludes the draft
  row's own id. Full cycle prevention stays on the backend (as
  `InventoryGroupService.assertNoCycle` does). Worked example:
  `inventory_group_manifest.dart`, `account_group_manifest.dart`. Department
  parent can adopt the same field when prioritized.
  Optional later: indented tree UI in the list (list already shows `depth` /
  `full_path` when the API sends them).
- **`FieldType.enum`/`json`/`binary`** — add only when a real entity needs
  one; don't pre-build.
- **`ManifestRegistry`** / generic `/m/:manifestId/...` routing — still
  register routes individually per entity (3 manifests isn't enough
  pressure yet). Revisit if registering masters by hand becomes the actual
  bottleneck, not before.
- **`MasterDetailSurface`** — edit-mode `MasterFormSurface` with fields
  disabled via `PermissionGate` serves as the read-only view. Revisit only
  if that reads badly in real use.

## When an entity doesn't fit

Per the Wave A5 rule: if an entity needs something this recipe doesn't
cover (a compound key, a 1:1 tab/section, a computed field), **stop and
note it** in `docs/manifest-exceptions.md` (create it if it doesn't exist)
rather than forking `MasterListSurface`/`MasterFormSurface` ad hoc for one
entity. The Surfaces stay generic; exceptions get named, not silently
worked around.
