import 'package:equatable/equatable.dart';

/// Wire shape of `/inventory/uom`, matching the backend `uomlist` table.
/// Field names keep the backend's original (mixed-case) casing per
/// `feature-contract.md` — the mapper produces clean entity names.
class UomDto extends Equatable {
  const UomDto({
    required this.id,
    required this.uomName,
    this.uomCode,
    this.decimalPlaces = 0,
    this.uomSymbol,
    this.isComposite = false,
  });

  factory UomDto.fromJson(Map<String, dynamic> json) => UomDto(
        id: json['id'] as int,
        uomName: json['uom_Name'] as String,
        uomCode: json['uom_code'] as String?,
        decimalPlaces: json['decimal_places'] as int? ?? 0,
        uomSymbol: json['uom_symbol'] as String?,
        isComposite: json['is_Composite'] as bool? ?? false,
      );

  final int id;
  final String uomName;
  final String? uomCode;
  final int decimalPlaces;
  final String? uomSymbol;
  final bool isComposite;

  /// `id`/timestamps are server-generated and never sent on write.
  Map<String, dynamic> toJson() => {
        'uom_Name': uomName,
        'uom_code': uomCode,
        'decimal_places': decimalPlaces,
        'uom_symbol': uomSymbol,
        'is_Composite': isComposite,
      };

  @override
  List<Object?> get props =>
      [id, uomName, uomCode, decimalPlaces, uomSymbol, isComposite];
}
