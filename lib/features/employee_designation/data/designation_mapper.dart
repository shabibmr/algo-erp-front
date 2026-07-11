import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/employee_designation/data/designation_dto.dart';
import 'package:algo_erp_front/features/employee_designation/domain/designation.dart';

class DesignationMapper implements Mapper<DesignationDto, Designation> {
  const DesignationMapper();

  @override
  Designation toEntity(DesignationDto dto) => Designation(
        id: dto.id,
        code: dto.designationCode,
        name: dto.designationName,
        departmentId: dto.departmentId,
        isActive: dto.isActive,
      );

  @override
  DesignationDto toDto(Designation entity) => DesignationDto(
        id: entity.id,
        designationCode: entity.code,
        designationName: entity.name,
        departmentId: entity.departmentId,
        isActive: entity.isActive,
      );
}
