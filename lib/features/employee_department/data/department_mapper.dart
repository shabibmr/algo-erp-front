import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/employee_department/data/department_dto.dart';
import 'package:algo_erp_front/features/employee_department/domain/department.dart';

class DepartmentMapper implements Mapper<DepartmentDto, Department> {
  const DepartmentMapper();

  @override
  Department toEntity(DepartmentDto dto) => Department(
    id: dto.id,
    code: dto.deptCode,
    name: dto.deptName,
    isActive: dto.isActive,
  );

  @override
  DepartmentDto toDto(Department entity) => DepartmentDto(
    id: entity.id,
    deptCode: entity.code,
    deptName: entity.name,
    isActive: entity.isActive,
  );
}
