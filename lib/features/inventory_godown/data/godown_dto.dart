import 'package:equatable/equatable.dart';

/// Wire shape of `/inventory/godown`, matching the backend `godown` table.
class GodownDto extends Equatable {
  const GodownDto({
    required this.id,
    required this.godownName,
    this.godownCode,
    this.godownLocation,
    this.godownNarration,
    this.isProfitCentre = false,
    this.isDefault = false,
    this.isProduction = false,
  });

  factory GodownDto.fromJson(Map<String, dynamic> json) => GodownDto(
    id: json['id'] as int,
    godownName: json['Godown_Name'] as String,
    godownCode: json['godown_code'] as String?,
    godownLocation: json['Godown_Location'] as String?,
    godownNarration: json['Godown_Narration'] as String?,
    isProfitCentre: json['is_profit_centre'] as bool? ?? false,
    isDefault: json['is_default'] as bool? ?? false,
    isProduction: json['is_production'] as bool? ?? false,
  );

  final int id;
  final String godownName;
  final String? godownCode;
  final String? godownLocation;
  final String? godownNarration;
  final bool isProfitCentre;
  final bool isDefault;
  final bool isProduction;

  Map<String, dynamic> toJson() => {
    'Godown_Name': godownName,
    'godown_code': godownCode,
    'Godown_Location': godownLocation,
    'Godown_Narration': godownNarration,
    'is_profit_centre': isProfitCentre,
    'is_default': isDefault,
    'is_production': isProduction,
  };

  @override
  List<Object?> get props => [
    id,
    godownName,
    godownCode,
    godownLocation,
    godownNarration,
    isProfitCentre,
    isDefault,
    isProduction,
  ];
}
