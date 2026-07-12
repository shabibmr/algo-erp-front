import 'package:equatable/equatable.dart';

const _unset = Object();

/// The Godown master entity — hard-deleted (no `is_active` column on the
/// backend `godown` table).
class Godown extends Equatable {
  const Godown({
    required this.id,
    required this.name,
    this.code,
    this.location,
    this.narration,
    this.isProfitCentre = false,
    this.isDefault = false,
    this.isProduction = false,
  });

  final int id;
  final String name;
  final String? code;
  final String? location;
  final String? narration;
  final bool isProfitCentre;
  final bool isDefault;
  final bool isProduction;

  Godown copyWith({
    int? id,
    String? name,
    Object? code = _unset,
    Object? location = _unset,
    Object? narration = _unset,
    bool? isProfitCentre,
    bool? isDefault,
    bool? isProduction,
  }) => Godown(
    id: id ?? this.id,
    name: name ?? this.name,
    code: identical(code, _unset) ? this.code : code as String?,
    location: identical(location, _unset) ? this.location : location as String?,
    narration: identical(narration, _unset)
        ? this.narration
        : narration as String?,
    isProfitCentre: isProfitCentre ?? this.isProfitCentre,
    isDefault: isDefault ?? this.isDefault,
    isProduction: isProduction ?? this.isProduction,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    location,
    narration,
    isProfitCentre,
    isDefault,
    isProduction,
  ];
}
