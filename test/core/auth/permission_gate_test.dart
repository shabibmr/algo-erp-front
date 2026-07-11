import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/auth/permission_service.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Always denies — proves the gate hides its child and shows the fallback.
class _DenyAllPermissionService implements PermissionService {
  const _DenyAllPermissionService();

  @override
  bool can(String module, PermissionAction action) => false;
}

void main() {
  tearDown(() async => getIt.reset());

  Future<void> pumpGate(WidgetTester tester, PermissionService service) async {
    getIt.registerSingleton<PermissionService>(service);
    await tester.pumpWidget(
      const MaterialApp(
        home: PermissionGate(
          module: 'Brand',
          action: PermissionAction.create,
          fallback: Text('denied'),
          child: Text('allowed'),
        ),
      ),
    );
  }

  testWidgets('shows child when the service permits the action', (
    tester,
  ) async {
    await pumpGate(tester, const FailOpenPermissionService());
    expect(find.text('allowed'), findsOneWidget);
    expect(find.text('denied'), findsNothing);
  });

  testWidgets('shows fallback when the service denies the action', (
    tester,
  ) async {
    await pumpGate(tester, const _DenyAllPermissionService());
    expect(find.text('denied'), findsOneWidget);
    expect(find.text('allowed'), findsNothing);
  });
}
