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

/// Which edge a ledger column's cells align to.
enum ColumnAlign { start, end }

/// Describes one field of an entity for manifest-driven rendering.
///
/// [key] is the entity-side (mapped, camelCase) field name; [cellValue] reads
/// the display string for that field off an entity instance of type [E].
/// Kept as a value-reading closure (rather than a `dynamic` getter + separate
/// formatter) so `MasterListSurface` never needs entity-specific knowledge.
///
/// **Presentation is derived, not declared.** [align] and [mono] default to
/// whatever [type] implies — numbers align right in tabular mono figures, so
/// they stack on the decimal down a column; everything else reads left in the
/// body face. A manifest only names these when it wants to override the
/// derivation, which is why adding them broke no existing manifest.
@immutable
class FieldSpec<E> {
  const FieldSpec({
    required this.key,
    required this.label,
    required this.type,
    required this.cellValue,
    this.required = false,
    this.flex = 1,
    this.minWidth = 96,
    ColumnAlign? align,
    bool? mono,
    this.primary = false,
    this.exportValue,
  }) : align =
           align ??
           (type == FieldType.int || type == FieldType.decimal
               ? ColumnAlign.end
               : ColumnAlign.start),
       mono = mono ?? (type == FieldType.int || type == FieldType.decimal);

  final String key;
  final String label;
  final FieldType type;
  final bool required;

  /// This column's share of the ledger's width, relative to its siblings.
  final int flex;

  /// Below this, the ledger stops flexing and scrolls horizontally instead.
  final double minWidth;

  /// Which edge cells align to. Numbers right, everything else left, unless
  /// the manifest overrides it.
  final ColumnAlign align;

  /// Whether cells render in tabular mono figures. Numbers do, unless the
  /// manifest overrides it.
  final bool mono;

  /// Marks the identity column — the value a clerk scans for. Rendered in ink
  /// at `w600`. `LedgerTable` promotes the first column by default, so most
  /// manifests never set this.
  final bool primary;

  /// Renders this field's value for `entity` as display text.
  final String Function(E entity) cellValue;

  /// The *untyped* value for a spreadsheet export, when [cellValue]'s display
  /// string cannot be reliably read back into one.
  ///
  /// Export normally derives the cell's type from [type] and recovers the value
  /// by parsing [cellValue] — `AED 1,234.50` back to `1234.5`, `07/11/2026`
  /// back to a date. That covers the manifests we have. This is the escape
  /// hatch for a column whose display string is genuinely lossy (a computed
  /// summary, a joined list, a value rendered through a lookup), where the
  /// parse would either fail or, worse, quietly produce the wrong number.
  ///
  /// Return a `num`, `Decimal`, `DateTime`, `bool`, `String`, or null for
  /// blank. Wins over [cellValue] when present.
  final Object? Function(E entity)? exportValue;
}
