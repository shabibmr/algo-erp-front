import 'package:algo_erp_front/features/organization_user_role/data/user_role_dto.dart';
import 'package:algo_erp_front/features/organization_user_role/data/user_role_mapper.dart';
import 'package:algo_erp_front/features/organization_user_role/domain/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = UserRoleMapper();

  test("UserRoleDto.fromJson reads the backend's exact wire casing", () {
    final dto = UserRoleDto.fromJson(const {
      'id': 1,
      'role_name': 'Administrator',
      'description': 'Admin access',
    });

    expect(dto.id, 1);
    expect(dto.roleName, 'Administrator');
    expect(dto.description, 'Admin access');
  });

  test('UserRoleMapper.toEntity produces a clean-named UserRole', () {
    const dto = UserRoleDto(id: 1, roleName: 'Administrator');
    expect(mapper.toEntity(dto), const UserRole(id: 1, name: 'Administrator'));
  });

  test('UserRoleMapper.toDto round-trips back to the wire shape', () {
    const role = UserRole(id: 1, name: 'Administrator');
    expect(mapper.toDto(role).toJson(), {
      'role_name': 'Administrator',
      'description': null,
    });
  });

  test('round-trip toEntity(toDto(x)) is identity', () {
    const role = UserRole(id: 5, name: 'Guest', description: 'Read only');
    expect(mapper.toEntity(mapper.toDto(role)), role);
  });
}
