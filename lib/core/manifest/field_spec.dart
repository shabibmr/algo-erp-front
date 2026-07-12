import 'package:flutter/foundation.dart';

/// The kinds of data a [FieldSpec]/`FormFieldSpec` can describe. Grows from
/// real pressure, not speculation — each case here is demanded by an entity
/// actually being built (Brand, Department, Designation).
///
/// Still deliberately deferred: `enum` (free-string + validator is fine for
/// now), `json`, `binary`.
enum FieldType {
  /// A plain string value, required or optional per `FieldSpec.required`.
  text,

  /// A read-only timestamp, formatted for display only (no form input yet —
  /// there is no form Surface in this slice).
  dateTime,

  /// A whole-number value (e.g. decimal places, counts).
  int,

  /// A decimal value (money/qty) — always `package:decimal`'s `Decimal`,
  /// never `double`.
  decimal,

  /// A boolean flag (e.g. `is_active`).
  bool,

  /// A foreign-key reference: the entity stores the related row's raw id,
  /// but the form renders/searches by the related row's display value via
  /// `FormFieldSpec.fkSearch`/`fkDisplayOf`/`fkResolveById`.
  fk,

  /// Self-referential parent FK (same entity type as the form). Uses the same
  /// picker as [fk]; the master form surface excludes the draft's own id from
  /// search results. Deeper cycle checks stay on the backend.
  selfFk,
}

/// Describes one field of an entity for manifest-driven rendering.
///
/// [key] is the entity-side (mapped, camelCase) field name; [cellValue] reads
/// the display string for that field off an entity instance of type [E].
/// Kept as a value-reading closure (rather than a `dynamic` getter + separate
/// formatter) so `MasterListSurface` never needs entity-specific knowledge.
@immutable
class FieldSpec<E> {
  const FieldSpec({
    required this.key,
    required this.label,
    required this.type,
    required this.cellValue,
    this.required = false,
  });

  final String key;
  final String label;
  final FieldType type;
  final bool required;

  /// Renders this field's value for `entity` as display text.
  final String Function(E entity) cellValue;
}
