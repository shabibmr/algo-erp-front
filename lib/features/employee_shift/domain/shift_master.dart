import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// Shift master. Backend exposes list + create only.
class ShiftMaster extends Equatable {
  const ShiftMaster({
    required this.id,
    required this.code,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.workingHours,
    this.breakMinutes = 0,
    this.isNightShift = false,
    this.isActive = true,
  });

  final int id;
  final String code;
  final String name;

  /// Wire as `HH:mm:ss`.
  final String startTime;
  final String endTime;
  final Decimal workingHours;
  final int breakMinutes;
  final bool isNightShift;
  final bool isActive;

  ShiftMaster copyWith({
    int? id,
    String? code,
    String? name,
    String? startTime,
    String? endTime,
    Decimal? workingHours,
    int? breakMinutes,
    bool? isNightShift,
    bool? isActive,
  }) => ShiftMaster(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    workingHours: workingHours ?? this.workingHours,
    breakMinutes: breakMinutes ?? this.breakMinutes,
    isNightShift: isNightShift ?? this.isNightShift,
    isActive: isActive ?? this.isActive,
  );

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    startTime,
    endTime,
    workingHours,
    breakMinutes,
    isNightShift,
    isActive,
  ];
}
