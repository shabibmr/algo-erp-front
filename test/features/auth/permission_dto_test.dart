import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/features/auth/data/dtos/auth_user_dto.dart';
import 'package:algo_erp_front/features/auth/data/dtos/permission_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("PermissionDto.fromJson reads the backend's exact wire casing", () {
    final dto = PermissionDto.fromJson(const {
      'module_name': 'Brand',
      'Allow_Create': true,
      'Allow_Read': true,
      'Allow_Update': false,
      'Allow_Delete': false,
      'Allow_Share': false,
    });

    expect(dto.moduleName, 'Brand');
    expect(dto.allowCreate, isTrue);
    expect(dto.allowRead, isTrue);
    expect(dto.allowUpdate, isFalse);
  });

  test('PermissionDto.fromJson coerces tinyint flags, nulls read false', () {
    final dto = PermissionDto.fromJson(const {
      'module_name': 'Currency',
      'Allow_Create': 1,
      'Allow_Read': 0,
      'Allow_Update': null,
    });

    expect(dto.allowCreate, isTrue);
    expect(dto.allowRead, isFalse);
    expect(dto.allowUpdate, isFalse);
    expect(dto.allowShare, isFalse);
  });

  test('PermissionDto.toEntity maps onto ModulePermissions', () {
    const dto = PermissionDto(
      moduleName: 'Brand',
      allowCreate: true,
      allowDelete: true,
    );

    expect(
      dto.toEntity(),
      const ModulePermissions(module: 'Brand', create: true, delete: true),
    );
  });

  test('AuthUserDto reads the permissions array /auth/me embeds', () {
    final dto = AuthUserDto.fromJson(const {
      'id': 1,
      'username': 'brand.tester',
      'roleId': 2,
      'roleName': 'Tester',
      'permissions': [
        {'module_name': 'Brand', 'Allow_Read': true},
      ],
    });

    expect(dto.permissions, hasLength(1));
    expect(dto.permissions!.single.moduleName, 'Brand');
    expect(dto.permissions!.single.allowRead, isTrue);
  });

  test('AuthUserDto leaves permissions null when absent, as on login', () {
    final dto = AuthUserDto.fromJson(const {
      'id': 1,
      'username': 'brand.tester',
      'roleId': 2,
      'roleName': 'Tester',
    });

    // Null means "this response didn't carry the matrix" — distinct from an
    // empty list, which means "the role genuinely has no permissions".
    expect(dto.permissions, isNull);
  });
}
