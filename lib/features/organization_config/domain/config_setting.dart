import 'package:equatable/equatable.dart';

const _unset = Object();

/// Config key/value. Read/update by [key]; no create/delete routes.
class ConfigSetting extends Equatable {
  const ConfigSetting({
    required this.id,
    required this.key,
    required this.value,
    this.dataType,
    this.displayText,
  });

  final int id;
  final String key;
  final String value;
  final String? dataType;
  final String? displayText;

  ConfigSetting copyWith({
    int? id,
    String? key,
    String? value,
    Object? dataType = _unset,
    Object? displayText = _unset,
  }) => ConfigSetting(
    id: id ?? this.id,
    key: key ?? this.key,
    value: value ?? this.value,
    dataType: identical(dataType, _unset) ? this.dataType : dataType as String?,
    displayText: identical(displayText, _unset)
        ? this.displayText
        : displayText as String?,
  );

  @override
  List<Object?> get props => [id, key, value, dataType, displayText];
}
