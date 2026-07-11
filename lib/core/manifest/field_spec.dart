import 'package:flutter/foundation.dart';

/// The kinds of data a [FieldSpec] can describe. Deliberately **small** —
/// only what Brand (the EMR vertical slice's proving ground) needs.
///
/// This enum grows from real pressure, not speculation. The next real
/// entities each demand a type this slice doesn't build yet:
/// - `LedgerMaster` needs `decimal` (`Opening_Balance`) and `fk`
///   (`account_group_id`).
/// - `AccountGroup` needs `selfFk` (`parent_group_id`, a tree parent picker).
/// - `AddressBook` needs `boolean` and a free-string `enum`.
/// Add a case only when a manifest actually needs it.
enum FieldType {
  /// A plain string value, required or optional per `FieldSpec.required`.
  text,

  /// A read-only timestamp, formatted for display only (no form input yet —
  /// there is no form Surface in this slice).
  dateTime,
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
