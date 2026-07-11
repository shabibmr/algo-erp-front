import 'package:algo_erp_front/core/theme/app_theme.dart';
import 'package:algo_erp_front/core/widgets/data_display/adaptive_entity_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Brand {
  const _Brand(this.id, this.name);
  final int id;
  final String name;
}

Widget _buildList() {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: AdaptiveEntityList<_Brand>(
        items: const [_Brand(1, 'Acme'), _Brand(2, 'Northwind')],
        keyOf: (b) => b.id,
        columns: [
          EntityColumn(label: 'Name', cellBuilder: (_, b) => Text(b.name)),
        ],
        cardBuilder: (_, b) => Text(b.name),
      ),
    ),
  );
}

void main() {
  testWidgets('renders cards at mobile width', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 800);

    await tester.pumpWidget(_buildList());

    expect(find.byType(DataTable), findsNothing);
    expect(find.byType(Card), findsNWidgets(2));
    expect(find.text('Acme'), findsOneWidget);
  });

  testWidgets('renders a DataTable at desktop width', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1400, 900);

    await tester.pumpWidget(_buildList());

    expect(find.byType(DataTable), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    expect(find.text('Northwind'), findsOneWidget);
  });
}
