import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MatrixPermissionService service;

  setUp(() => service = MatrixPermissionService());

  test('denies everything before a matrix is loaded', () {
    for (final action in PermissionAction.values) {
      expect(service.can('Brand', action), isFalse);
    }
  });

  test('answers each action from the loaded row', () {
    service.load(const [
      ModulePermissions(module: 'Brand', create: true, read: true),
    ]);

    expect(service.can('Brand', PermissionAction.create), isTrue);
    expect(service.can('Brand', PermissionAction.read), isTrue);
    expect(service.can('Brand', PermissionAction.update), isFalse);
    expect(service.can('Brand', PermissionAction.delete), isFalse);
    expect(service.can('Brand', PermissionAction.share), isFalse);
  });

  test('denies a module with no row, exactly as the server does', () {
    service.load(const [ModulePermissions(module: 'Brand', read: true)]);
    expect(service.can('Currency', PermissionAction.read), isFalse);
  });

  test('load replaces the previous matrix rather than merging into it', () {
    service
      ..load(const [ModulePermissions(module: 'Brand', read: true)])
      ..load(const [ModulePermissions(module: 'Currency', read: true)]);

    expect(service.can('Brand', PermissionAction.read), isFalse);
    expect(service.can('Currency', PermissionAction.read), isTrue);
  });

  test('clear returns to deny-all on sign-out', () {
    service
      ..load(const [ModulePermissions(module: 'Brand', read: true)])
      ..clear();

    expect(service.can('Brand', PermissionAction.read), isFalse);
  });
}
