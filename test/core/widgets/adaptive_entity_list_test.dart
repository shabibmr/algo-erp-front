import 'package:algo_erp_front/core/theme/app_theme.dart';
import 'package:algo_erp_front/core/widgets/data_display/adaptive_entity_list.dart';
import 'package:algo_erp_front/core/widgets/data_display/ledger_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Brand {
  const _Brand(this.id, this.code, this.name);
  final int id;
  final String code;
  final String name;
}

const _brands = [
  _Brand(1, 'BRD-001', 'Acme'),
  _Brand(2, 'BRD-002', 'Northwind'),
];

Widget _buildList({List<_Brand> items = _brands}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: AdaptiveEntityList<_Brand>(
        items: items,
        keyOf: (b) => b.id,
        columns: [
          EntityColumn(
            label: 'Code',
            mono: true,
            primary: true,
            cellBuilder: (_, b) => Text(b.code),
          ),
          EntityColumn(
            label: 'Name',
            flex: 3,
            cellBuilder: (_, b) => Text(b.name),
          ),
        ],
      ),
    ),
  );
}

void _sizeTo(WidgetTester tester, Size size) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
}

void main() {
  testWidgets('renders index cards at mobile width', (tester) async {
    _sizeTo(tester, const Size(400, 800));

    await tester.pumpWidget(_buildList());

    expect(find.byType(LedgerTable<_Brand>), findsNothing);
    // The default card: the identity value as a heading, the rest as labelled
    // lines — not a squeezed table.
    expect(find.text('BRD-001'), findsOneWidget);
    expect(find.text('Name'), findsNWidgets(2));
    expect(find.text('Acme'), findsOneWidget);
  });

  testWidgets('renders the ledger at desktop width', (tester) async {
    _sizeTo(tester, const Size(1400, 900));

    await tester.pumpWidget(_buildList());

    expect(find.byType(LedgerTable<_Brand>), findsOneWidget);
    expect(find.text('Northwind'), findsOneWidget);
    // Header labels are set in small caps.
    expect(find.text('CODE'), findsOneWidget);
  });

  testWidgets('columns flex to fill the sheet rather than hugging content', (
    tester,
  ) async {
    _sizeTo(tester, const Size(1400, 900));

    await tester.pumpWidget(_buildList());

    // The ledger is the sheet: it spans the full width it was given, instead
    // of sizing to its intrinsic content and floating in an empty page.
    final width = tester.getSize(find.byType(LedgerTable<_Brand>)).width;
    expect(width, 1400);
  });
}
