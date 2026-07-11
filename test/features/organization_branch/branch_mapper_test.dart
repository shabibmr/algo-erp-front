import 'package:algo_erp_front/features/organization_branch/data/branch_dto.dart';
import 'package:algo_erp_front/features/organization_branch/data/branch_mapper.dart';
import 'package:algo_erp_front/features/organization_branch/domain/branch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = BranchMapper();

  test("BranchDto.fromJson reads the backend's exact wire casing", () {
    final dto = BranchDto.fromJson(const {
      'id': 1,
      'branch_code': 'HO',
      'branch_name': 'Head Office',
      'company_id': 7,
      'address': '123 Main St',
      'is_active': false,
    });

    expect(dto.id, 1);
    expect(dto.branchCode, 'HO');
    expect(dto.branchName, 'Head Office');
    expect(dto.companyId, 7);
    expect(dto.address, '123 Main St');
    expect(dto.isActive, false);
  });

  test('BranchDto.fromJson defaults isActive to true when absent', () {
    final dto = BranchDto.fromJson(const {
      'id': 1,
      'branch_code': 'HO',
      'branch_name': 'Head Office',
      'company_id': 7,
    });

    expect(dto.isActive, true);
    expect(dto.address, isNull);
  });

  test('BranchMapper.toEntity maps dto fields to entity fields', () {
    const dto = BranchDto(
      id: 1,
      branchCode: 'HO',
      branchName: 'Head Office',
      companyId: 7,
      address: '123 Main St',
      isActive: false,
    );

    expect(
      mapper.toEntity(dto),
      const Branch(
        id: 1,
        code: 'HO',
        name: 'Head Office',
        companyId: 7,
        address: '123 Main St',
        isActive: false,
      ),
    );
  });

  test(
      'BranchMapper.toDto round-trips back to the wire shape '
      '(omitting isActive)', () {
    const branch = Branch(
      id: 1,
      code: 'HO',
      name: 'Head Office',
      companyId: 7,
      address: '123 Main St',
    );

    expect(mapper.toDto(branch).toJson(), {
      'branch_code': 'HO',
      'branch_name': 'Head Office',
      'company_id': 7,
      'address': '123 Main St',
    });
  });

  test('round-trip toEntity(toDto(x)) is identity', () {
    const branch = Branch(
      id: 5,
      code: 'BR2',
      name: 'Branch Two',
      companyId: 3,
      isActive: false,
    );
    expect(mapper.toEntity(mapper.toDto(branch)), branch);
  });
}
