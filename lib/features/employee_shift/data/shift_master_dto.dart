import 'package:equatable/equatable.dart';

class ShiftMasterDto extends Equatable {
  const ShiftMasterDto({
    required this.id,
    required this.shiftCode,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    required this.workingHours,
    this.breakMinutes = 0,
    this.isNightShift = false,
    this.isActive = true,
  });

  factory ShiftMasterDto.fromJson(Map<String, dynamic> json) {
    String timeOf(Object? raw) {
      if (raw == null) return '00:00:00';
      if (raw is String) {
        // ISO datetime from Prisma DateTime → extract time part.
        if (raw.contains('T')) {
          final t = raw.split('T').last;
          return t.length >= 8 ? t.substring(0, 8) : t;
        }
        return raw.length >= 8 ? raw.substring(0, 8) : raw;
      }
      return '00:00:00';
    }

    return ShiftMasterDto(
      id: json['id'] as int,
      shiftCode: json['shift_code'] as String? ?? '',
      shiftName: json['shift_name'] as String? ?? '',
      startTime: timeOf(json['start_time']),
      endTime: timeOf(json['end_time']),
      workingHours: json['working_hours']?.toString() ?? '0',
      breakMinutes: json['break_minutes'] as int? ?? 0,
      isNightShift: json['is_night_shift'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  final int id;
  final String shiftCode;
  final String shiftName;
  final String startTime;
  final String endTime;
  final String workingHours;
  final int breakMinutes;
  final bool isNightShift;
  final bool isActive;

  Map<String, dynamic> toJson() => {
    'shift_code': shiftCode,
    'shift_name': shiftName,
    'start_time': startTime,
    'end_time': endTime,
    'working_hours': double.tryParse(workingHours) ?? 0,
    'break_minutes': breakMinutes,
    'is_night_shift': isNightShift,
    'is_active': isActive,
  };

  @override
  List<Object?> get props => [
    id,
    shiftCode,
    shiftName,
    startTime,
    endTime,
    workingHours,
    breakMinutes,
    isNightShift,
    isActive,
  ];
}
