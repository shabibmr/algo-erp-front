import 'package:algo_erp_front/features/organization_project/data/project_master_dto.dart';
import 'package:algo_erp_front/features/organization_project/data/project_master_mapper.dart';
import 'package:algo_erp_front/features/organization_project/domain/project_master.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = ProjectMasterMapper();

  test("ProjectMasterDto.fromJson reads the backend's exact wire casing", () {
    final dto = ProjectMasterDto.fromJson(const {
      'id': 3,
      'PROJECT_ID': 'PRJ-01',
      'Project_Name': 'Site A',
      'project_code': 'A1',
      'parent_project_master_id': 1,
      'Project_Status': 'Active',
      'Start_Date': '2026-01-01T00:00:00.000Z',
      'Estimated_Value': 1500.5,
    });

    expect(dto.id, 3);
    expect(dto.projectId, 'PRJ-01');
    expect(dto.projectName, 'Site A');
    expect(dto.projectCode, 'A1');
    expect(dto.parentProjectMasterId, 1);
    expect(dto.projectStatus, 'Active');
    expect(dto.startDate, '2026-01-01');
    expect(dto.estimatedValue, Decimal.parse('1500.5'));
  });

  test('ProjectMasterMapper.toEntity maps dto fields', () {
    final dto = ProjectMasterDto(
      id: 3,
      projectId: 'PRJ-01',
      projectName: 'Site A',
      projectCode: 'A1',
      projectStatus: 'Active',
      estimatedValue: Decimal.parse('10'),
    );

    expect(
      mapper.toEntity(dto),
      ProjectMaster(
        id: 3,
        projectId: 'PRJ-01',
        name: 'Site A',
        projectCode: 'A1',
        status: 'Active',
        estimatedValue: Decimal.parse('10'),
      ),
    );
  });

  test('toJson omits id and empty optionals', () {
    const project = ProjectMaster(
      id: 9,
      projectId: 'X',
      name: 'Y',
      status: 'Pending',
    );

    expect(mapper.toDto(project).toJson(), {
      'PROJECT_ID': 'X',
      'Project_Name': 'Y',
      'parent_project_master_id': null,
      'project_owner_contact_id': null,
      'associated_ledger_id': null,
      'godown_id': null,
      'coordinator_employee_id': null,
      'Project_Status': 'Pending',
    });
  });
}
