import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/line_engine/line_engine.dart';
import 'package:algo_erp_front/core/surfaces/document_surface.dart';
import 'package:algo_erp_front/core/theme/app_theme.dart';
import 'package:algo_erp_front/core/vouchers/voucher_blueprint.dart';
import 'package:algo_erp_front/core/widgets/data_display/line_item_grid.dart';
import 'package:algo_erp_front/core/widgets/layout/work_sheet.dart';
import 'package:algo_erp_front/l10n/gen/app_localizations.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A throwaway line row — same discipline as `master_form_surface_test.dart`.
class _Line {
  const _Line({required this.qty, required this.price});
  final Decimal qty;
  final Decimal price;
}

/// These tests exercise layout, not RBAC.
class _AllowAllPermissionService implements PermissionService {
  const _AllowAllPermissionService();

  @override
  bool can(String module, PermissionAction action) => true;
}

void main() {
  setUpAll(() {
    getIt.registerSingleton<PermissionService>(
      const _AllowAllPermissionService(),
    );
  });

  tearDownAll(getIt.reset);

  final rows = <_Line>[
    _Line(qty: Decimal.fromInt(2), price: Decimal.fromInt(50)),
    _Line(qty: Decimal.fromInt(1), price: Decimal.fromInt(125)),
  ];

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  Widget surface({Widget? header}) {
    return DocumentSurface<_Line>(
      blueprint: VoucherBlueprints.salesInvoice,
      header: header,
      rows: rows,
      columns: [
        LineItemColumn<_Line>(
          label: 'Qty',
          cellBuilder: (_, row, _) => Text(row.qty.toString()),
        ),
        LineItemColumn<_Line>(
          label: 'Price',
          cellBuilder: (_, row, _) => Text(row.price.toString()),
        ),
      ],
      onRowsChanged: (_) {},
      lineInputsOf: (row) => LineInput(quantity: row.qty, price: row.price),
      onPost: () {},
    );
  }

  /// The line grid is an `Expanded` on desktop and a fixed-height box below it.
  /// Both now sit inside a `WorkSheet`, so the surface has to keep the grid in
  /// a Flex at every width or the desktop branch throws.
  for (final (label, size) in <(String, Size)>[
    ('mobile', Size(390, 844)),
    ('tablet', Size(834, 1112)),
    ('desktop', Size(1440, 900)),
    ('large', Size(1920, 1080)),
  ]) {
    testWidgets('renders without overflow at $label width', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(surface()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(LineItemGrid<_Line>), findsOneWidget);
      // Items panel + totals card, both on paper rather than ad-hoc tints.
      expect(find.byType(WorkSheet), findsAtLeastNWidgets(2));
    });
  }

  testWidgets('omits the header slot entirely when none is given', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(surface()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('doc-header')), findsNothing);

    await tester.pumpWidget(
      wrap(
        surface(
          header: const SizedBox(key: ValueKey('doc-header'), height: 20),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('doc-header')), findsOneWidget);
  });

  testWidgets('totals come from the line engine, not the widget tree', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(surface()));
    await tester.pumpAndSettle();

    // 2 × 50 + 1 × 125 = 225.00
    expect(find.text('AED 225.00'), findsAtLeastNWidgets(1));
  });
}
