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
  }) : assert(
          type != FieldType.fk ||
              (fkSearch != null &&
                  fkDisplayOf != null &&
                  fkResolveById != null),
          'FieldType.fk requires fkSearch, fkDisplayOf, and fkResolveById.',
        );

  /// The entity-side (mapped, camelCase) field name.
  final String key;

  final String label;
  final FieldType type;

  /// Reads the current value off the draft entity: `String?`, `int?`,
  /// `Decimal?`, `bool?`, or `DateTime?` — or, for [FieldType.fk], the raw
  /// foreign-key id (`Object?`).
  final Object? Function(E entity) getValue;

  /// Functional update: returns a **new** `E` with this field set to
  /// `value`. For [FieldType.fk], `value` is the raw foreign-key id.
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

  /// [FieldType.fk] only: search the related entity's own list endpoint,
  /// e.g. `(q) => departmentRepository.list(PageQuery(search: q))`.
  final Future<List<Object>> Function(String query)? fkSearch;

  /// [FieldType.fk] only: renders a related-entity search result as display
  /// text (e.g. a `Department`'s name).
  final String Function(Object item)? fkDisplayOf;

  /// [FieldType.fk] only: resolves a stored raw id back to its related
  /// entity, to seed the picker's initial label in edit mode (the draft
  /// entity only stores the raw id, not the related object).
  final Future<Object?> Function(Object id)? fkResolveById;

  /// The key server validation errors are matched against.
  String get errorKey => wireKey ?? key;
}
