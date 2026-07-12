import 'package:algo_erp_front/features/employee_shift/data/shift_master_dto.dart';
import 'package:algo_erp_front/features/employee_shift/data/shift_master_mapper.dart';
import 'package:algo_erp_front/features/employee_shift/domain/shift_master.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = ShiftMasterMapper();

  test('fromJson extracts HH:mm:ss from ISO datetime times', () {
    final dto = ShiftMasterDto.fromJson({
      'id': 1,
      'shift_code': 'D1',
      'shift_name': 'Day',
      'start_time': '1970-01-01T09:00:00.000Z',
      'end_time': '1970-01-01T18:00:00.000Z',
      'working_hours': '8.0',
      'break_minutes': 60,
      'is_night_shift': false,
    });
    expect(dto.startTime, '09:00:00');
    expect(dto.endTime, '18:00:00');
    final entity = mapper.toEntity(dto);
    expect(entity.workingHours, Decimal.parse('8.0'));
  });

  test('toJson sends times as HH:mm:ss and numeric hours', () {
    final entity = ShiftMaster(
      id: 0,
      code: 'N1',
      name: 'Night',
      startTime: '22:00:00',
      endTime: '06:00:00',
      workingHours: Decimal.fromInt(8),
      isNightShift: true,
    );
    final json = mapper.toDto(entity).toJson();
    expect(json['start_time'], '22:00:00');
    expect(json['working_hours'], 8.0);
    expect(json['is_night_shift'], isTrue);
  });
}
