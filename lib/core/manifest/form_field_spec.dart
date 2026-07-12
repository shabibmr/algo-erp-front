import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:flutter/widgets.dart';

/// Describes one create/edit field of an entity for `MasterFormSurface`.
///
/// Kept separate from the list-only [FieldSpec]: a list column only ever
/// needs a display-string closure, while a form field needs typed
/// get/set access plus (for [FieldType.fk]) a search/display/resolve triple.
/// Folding both into one class would put unused FK params on every
/// text/dateTime list column.
@immutable
class FormFieldSpec<E> {
  const FormFieldSpec({
    required this.key,
    required this.label,
    required this.type,
    required this.getValue,
    required this.setValue,
    this.wireKey,
    this.required = false,
    this.readOnly = false,
    this.helperText,
    this.hintText,
    this.validator,
    this.fkSearch,
    this.fkDisplayOf,
    this.fkResolveById,
    this.section,
    this.half = false,
  }) : assert(
         (type != FieldType.fk && type != FieldType.selfFk) ||
             (fkSearch != null && fkDisplayOf != null && fkResolveById != null),
         'FieldType.fk/selfFk requires fkSearch, fkDisplayOf, and fkResolveById.',
       );

  /// The entity-side (mapped, camelCase) field name.
  final String key;

  final String label;
  final FieldType type;

  /// Reads the current value off the draft entity: `String?`, `int?`,
  /// `Decimal?`, `bool?`, or `DateTime?` — or, for [FieldType.fk]/[FieldType.selfFk],
  /// the raw foreign-key id (`Object?`).
  final Object? Function(E entity) getValue;

  /// Functional update: returns a **new** `E` with this field set to
  /// `value`. For [FieldType.fk]/[FieldType.selfFk], `value` is the selected
  /// related object (surface caches it); extract the id in [setValue].
  final E Function(E entity, Object? value) setValue;

  /// The backend's Zod-validated wire key (e.g. `'Brand_Name'`), used to
  /// match `FormMixin.fieldErrorsFrom` results back to this field. Defaults
  /// to [key] when unset.
  final String? wireKey;

  final bool required;

  /// When true, the field renders but is never editable (submit-disabled),
  /// regardless of the caller's RBAC permission.
  final bool readOnly;

  final String? helperText;
  final String? hintText;
  final FormFieldValidator<Object?>? validator;

  /// [FieldType.fk]/[FieldType.selfFk] only: search the related entity's
  /// list endpoint (e.g. department repository `list` with `PageQuery.search`).
  final Future<List<Object>> Function(String query)? fkSearch;

  /// [FieldType.fk]/[FieldType.selfFk] only: renders a related-entity search
  /// result as display text (e.g. a `Department`'s name).
  final String Function(Object item)? fkDisplayOf;

  /// [FieldType.fk]/[FieldType.selfFk] only: resolves a stored raw id back to
  /// its related entity, to seed the picker's initial label in edit mode.
  final Future<Object?> Function(Object id)? fkResolveById;

  /// Which index card this field is filed under. Fields sharing a section
  /// render together in one card, in manifest order, with the section name as
  /// the card's header. Leave null and the field lands on the form's single
  /// unnamed card — which is why adding sections broke no existing manifest.
  final String? section;

  /// Lets this field share a row with the next half-width field on desktop.
  /// Ignored below tablet, where every field is full width.
  final bool half;

  /// The key server validation errors are matched against.
  String get errorKey => wireKey ?? key;
}
