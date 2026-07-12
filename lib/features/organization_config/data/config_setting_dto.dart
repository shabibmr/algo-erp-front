import 'package:equatable/equatable.dart';

/// Wire shape of `/organization/config` / `config_settings`.
class ConfigSettingDto extends Equatable {
  const ConfigSettingDto({
    required this.id,
    required this.gmKey,
    required this.gmValue,
    this.dataType,
    this.displayText,
  });

  factory ConfigSettingDto.fromJson(Map<String, dynamic> json) =>
      ConfigSettingDto(
        id: json['id'] as int,
        gmKey: json['gm_key'] as String? ?? '',
        gmValue: json['gm_value'] as String? ?? '',
        dataType: json['Data_Type'] as String?,
        displayText: json['display_text'] as String?,
      );

  final int id;
  final String gmKey;
  final String gmValue;
  final String? dataType;
  final String? displayText;

  /// Update body is `{ value }` only — not a full row write.
  Map<String, dynamic> toUpdateJson() => {'value': gmValue};

  @override
  List<Object?> get props => [id, gmKey, gmValue, dataType, displayText];
}
