import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:flutter/foundation.dart';

/// The typed declaration a `MasterListSurface<E>` renders: what the entity is
/// called, which permission module gates it, where its data lives, and which
/// fields appear as list columns.
///
/// This is the EMR vertical slice's entire manifest model — no
/// `formSections`, no FK/tree specs, no voucher blueprint. Those are real
/// ideas from `docs/BUILD_TASKS_V2.md` but unvalidated until this slice
/// (Brand's list, end to end) proves the pattern is worth extending.
@immutable
class EntityManifest<E> {
  EntityManifest({
    required this.id,
    required this.label,
    required this.rbacModule,
    required this.resourcePath,
    required this.listColumns,
    this.searchFields = const [],
    this.supportsPrint = false,
    this.supportsExcel = false,
    this.shareActions = const [],
    this.formFields = const [],
    this.emptyEntity,
    this.hardDelete = false,
    this.supportsUpdate = true,
    this.supportsDelete = true,
  }) : assert(
          formFields.isEmpty || emptyEntity != null,
          'A manifest with formFields must supply emptyEntity for create mode.',
        );

  /// Stable identifier for this manifest (e.g. `'brand'`).
  final String id;

  /// Display name (e.g. `'Brand'`) — plural/singular handling is caller-side.
  final String label;

  /// The backend's `authorize()` module string — **not** always the same as
  /// [label]. Confirmed per entity against the backend source; e.g. Brand's
  /// routes gate on the coarse `'Inventory'` string, not `'Brand'`.
  final String rbacModule;

  /// The REST resource path (e.g. `'/inventory/brand'`), passed straight to
  /// `RemoteDataSourceBase`.
  final String resourcePath;

  /// Columns rendered by `AdaptiveEntityList` on the list Surface, in order.
  final List<FieldSpec<E>> listColumns;

  /// Field keys forwarded as `PageQuery.search` targets. Purely documentation
  /// today — the backend doesn't yet honor search (BE-002) — but keeps the
  /// manifest ready for when it does.
  final List<String> searchFields;

  /// Whether this entity supports printing or exporting to PDF/print preview.
  final bool supportsPrint;

  /// Whether this entity supports Excel/CSV export.
  final bool supportsExcel;

  /// Share actions supported for this entity (e.g. `'email'`, `'whatsapp'`).
  final List<String> shareActions;

  /// Fields rendered by `MasterFormSurface` for create/edit, in order. Empty
  /// means this entity has no form yet (list-only, as Brand originally was).
  final List<FormFieldSpec<E>> formFields;

  /// Builds a blank draft entity for create mode. Required whenever
  /// [formFields] is non-empty.
  final E Function()? emptyEntity;

  /// Whether deleting this entity is permanent (drives confirmation copy).
  /// Most masters soft-delete via `is_active`; a few (e.g. Brand) hard-delete
  /// because the backend table has no `is_active` column.
  final bool hardDelete;

  /// Whether the backend exposes a working `PUT` for this entity. When
  /// `false`, `MasterFormSurface`'s edit mode renders fields read-only and
  /// hides the Save button (and form pages should title the screen "View"
  /// rather than "Edit"). Does not affect create mode. See
  /// `docs/manifest-spec.md` and `docs/manifest-exceptions.md`.
  final bool supportsUpdate;

  /// Whether the backend exposes a working `DELETE` for this entity. When
  /// `false`, `MasterFormSurface` hides the Delete action in edit mode
  /// and refuses delete at the action boundary as well.
  final bool supportsDelete;
}
