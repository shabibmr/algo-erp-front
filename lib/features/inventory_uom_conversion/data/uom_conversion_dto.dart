import 'package:equatable/equatable.dart';

/// Wire shape of `/inventory/conversion`, matching the backend
/// `uom_conversion` table.
class UomConversionDto extends Equatable {
  const UomConversionDto({
    required this.id,
    required this.baseUnit,
    required this.toUnit,
    required this.conValue,
    this.itemId,
    this.narration,
  });

  factory UomConversionDto.fromJson(Map<String, dynamic> json) =>
      UomConversionDto(
        id: json['id'] as int,
        baseUnit: json['baseUnit'] as String,
        toUnit: json['toUnit'] as String,
        conValue: json['conValue'] as String,
        itemId: json['itemID'] as String?,
        narration: json['narration'] as String?,
      );

  final int id;
  final String baseUnit;
  final String toUnit;
  final String conValue;
  final String? itemId;
  final String? narration;

  Map<String, dynamic> toJson() => {
    'baseUnit': baseUnit,
    'toUnit': toUnit,
    'conValue': conValue,
    'itemID': itemId,
    'narration': narration,
  };

  @override
  List<Object?> get props => [
    id,
    baseUnit,
    toUnit,
    conValue,
    itemId,
    narration,
  ];
}
