import 'package:algo_erp_front/features/employee_designation/data/designation_dto.dart';
import 'package:algo_erp_front/features/employee_designation/data/designation_mapper.dart';
import 'package:algo_erp_front/features/employee_designation/domain/designation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = DesignationMapper();

  test("DesignationDto.fromJson reads the backend's exact wire casing", () {
    final dto = DesignationDto.fromJson(const {
      'id': 1,
      'designation_code': 'MGR',
      'designation_name': 'Manager',
      'department_id': 4,
      'is_active': true,
    });

    expect(dto.id, 1);
    expect(dto.designationCode, 'MGR');
    expect(dto.designationName, 'Manager');
    expect(dto.departmentId, 4);
    expect(dto.isActive, isTrue);
  });

  test('DesignationDto.fromJson defaults isActive to true when absent', () {
    final dto = DesignationDto.fromJson(const {
      'id': 2,
      'designation_code': 'DEV',
      'designation_name': 'Developer',
      'department_id': 3,
    });
    expect(dto.isActive, isTrue);
  });

  test('DesignationMapper.toEntity produces a clean-named Designation', () {
    const dto = DesignationDto(
      id: 1,
      designationCode: 'MGR',
      designationName: 'Manager',
      departmentId: 4,
      isActive: true,
    );
    final designation = mapper.toEntity(dto);

    expect(
      designation,
      const Designation(id: 1, code: 'MGR', name: 'Manager', departmentId: 4),
    );
  });

  test('DesignationMapper.toDto round-trips back to the wire shape', () {
    const designation = Designation(
      id: 1,
      code: 'MGR',
      name: 'Manager',
      departmentId: 4,
    );
    final dto = mapper.toDto(designation);

    expect(dto.toJson(), {
      'designation_code': 'MGR',
      'designation_name': 'Manager',
      'department_id': 4,
      'is_active': true,
    });
  });

  test('round-trip toEntity(toDto(x)) is identity', () {
    const designation = Designation(
      id: 5,
      code: 'DEV',
      name: 'Developer',
      departmentId: 2,
      isActive: false,
    );
    expect(mapper.toEntity(mapper.toDto(designation)), designation);
  });
}
