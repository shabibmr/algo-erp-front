import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FailOpenPermissionService permits every module/action (BE-001)', () {
    const service = FailOpenPermissionService();
    for (final action in PermissionAction.values) {
      expect(service.can('AnyModule', action), isTrue);
    }
    // A different module name is treated identically.
    expect(service.can('SalesInvoice', PermissionAction.delete), isTrue);
  });
}
