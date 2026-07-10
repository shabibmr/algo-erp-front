import 'package:algo_erp_front/app.dart';
import 'package:algo_erp_front/core/config/app_config.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    AppConfig.init(
      const AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://localhost:3000'),
    );
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
  });

  testWidgets('App boots to the Dashboard route inside the adaptive shell', (
    tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(
      find.text('Feature not yet built — placeholder route from Step 3.'),
      findsOneWidget,
    );
  });

  testWidgets('Shell morphs from rail to a mobile drawer at narrow widths', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1.0;

    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);

    tester.view.physicalSize = const Size(400, 800);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });
}
