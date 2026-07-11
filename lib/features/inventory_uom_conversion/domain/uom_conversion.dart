import 'package:equatable/equatable.dart';

const _unset = Object();

/// The UOMConversion master entity — hard-deleted (no `is_active` column on
/// the backend `uom_conversion` table).
///
/// [conversionValue] stays a `String`, not a `Decimal`: the backend column
/// (`conValue`) is itself `VARCHAR`, not numeric, despite the value being
/// conceptually a number — see `docs/manifest-spec.md`'s note on not forcing
/// `FieldType.decimal` onto a non-numeric DB column.
class UomConversion extends Equatable {
  const UomConversion({
    required this.id,
    required this.baseUnit,
    required this.toUnit,
    required this.conversionValue,
    this.itemId,
    this.narration,
  });

  final int id;
  final String baseUnit;
  final String toUnit;
  final String conversionValue;
  final String? itemId;
  final String? narration;

  UomConversion copyWith({
    int? id,
    String? baseUnit,
    String? toUnit,
    String? conversionValue,
    Object? itemId = _unset,
    Object? narration = _unset,
  }) =>
      UomConversion(
        id: id ?? this.id,
        baseUnit: baseUnit ?? this.baseUnit,
        toUnit: toUnit ?? this.toUnit,
        conversionValue: conversionValue ?? this.conversionValue,
        itemId: identical(itemId, _unset) ? this.itemId : itemId as String?,
        narration: identical(narration, _unset)
            ? this.narration
            : narration as String?,
      );

  @override
  List<Object?> get props =>
      [id, baseUnit, toUnit, conversionValue, itemId, narration];
}
