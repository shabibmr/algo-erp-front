import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/employee_shift/data/shift_master_dto.dart';
import 'package:algo_erp_front/features/employee_shift/domain/shift_master.dart';
import 'package:decimal/decimal.dart';

class ShiftMasterMapper implements Mapper<ShiftMasterDto, ShiftMaster> {
  const ShiftMasterMapper();

  @override
  ShiftMaster toEntity(ShiftMasterDto dto) => ShiftMaster(
    id: dto.id,
    code: dto.shiftCode,
    name: dto.shiftName,
    startTime: dto.startTime,
    endTime: dto.endTime,
    workingHours: Decimal.tryParse(dto.workingHours) ?? Decimal.zero,
    breakMinutes: dto.breakMinutes,
    isNightShift: dto.isNightShift,
    isActive: dto.isActive,
  );

  @override
  ShiftMasterDto toDto(ShiftMaster entity) => ShiftMasterDto(
    id: entity.id,
    shiftCode: entity.code,
    shiftName: entity.name,
    startTime: entity.startTime,
    endTime: entity.endTime,
    workingHours: entity.workingHours.toString(),
    breakMinutes: entity.breakMinutes,
    isNightShift: entity.isNightShift,
    isActive: entity.isActive,
  );
}
