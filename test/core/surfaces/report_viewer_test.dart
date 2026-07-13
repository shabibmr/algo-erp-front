import 'package:algo_erp_front/core/reports/report_catalog.dart';
import 'package:algo_erp_front/core/reports/report_definition.dart';
import 'package:algo_erp_front/core/reports/report_repository.dart';
import 'package:algo_erp_front/core/surfaces/report_viewer.dart';
import 'package:algo_erp_front/core/theme/app_theme.dart';
import 'package:algo_erp_front/core/widgets/data_display/ledger_table.dart';
import 'package:algo_erp_front/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockReportRepository extends Mock implements ReportRepository {}

class _FakeReportDefinition extends Fake implements ReportDefinition {}

/// The real `GET /transactions/reports/balance-sheet` envelope `data`.
const _balanceSheetData = {
  'asOfDate': '2026-07-13',
  'assets': [
    {'ledgerId': 1, 'name': 'Cash', 'amount': 900},
    {'ledgerId': 2, 'name': 'Customer A', 'amount': 100},
  ],
  'liabilities': [
    {'ledgerId': 3, 'name': 'Vendor B', 'amount': 400},
  ],
  'capital': <Map<String, dynamic>>[],
  'retainedEarnings': 600,
  'totalAssets': 1000,
  'totalLiabilitiesAndCapital': 1000,
  'isBalanced': true,
};

void main() {
  late _MockReportRepository repo;

  setUpAll(() {
    registerFallbackValue(_FakeReportDefinition());
  });

  setUp(() {
    repo = _MockReportRepository();
    when(
      () => repo.fetch(any(), any()),
    ).thenAnswer((_) async => const Right(_balanceSheetData));
  });

  Widget wrap(ReportDefinition def) {
    return MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ReportViewer(definition: def, repository: repo),
      ),
    );
  }

  testWidgets(
    'the balance sheet renders a table per section, not just totals',
    (tester) async {
      await tester.pumpWidget(wrap(ReportCatalog.balanceSheet));
      await tester.pumpAndSettle();

      // Each section gets its own titled sheet...
      expect(find.text('Assets'), findsOneWidget);
      expect(find.text('Liabilities'), findsOneWidget);
      expect(find.text('Capital'), findsOneWidget);

      // ...with the ledger lines the old summary shape threw away.
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Customer A'), findsOneWidget);
      expect(find.text('Vendor B'), findsOneWidget);

      // Assets and Liabilities have rows; empty Capital renders no table.
      expect(find.byType(LedgerTable<Map<String, dynamic>>), findsNWidgets(2));
      expect(find.text('No entries.'), findsOneWidget);
    },
  );

  testWidgets('the totals block still reports the statement footing', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(ReportCatalog.balanceSheet));
    await tester.pumpAndSettle();

    expect(find.text('Totals'), findsOneWidget);
    expect(find.text('Total assets'), findsOneWidget);
    expect(find.text('Balanced'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);
  });

  testWidgets('it queries the fixed endpoint with end_date, not as_of_date', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(ReportCatalog.balanceSheet));
    await tester.pumpAndSettle();

    final captured = verify(
      () => repo.fetch(captureAny(), captureAny()),
    ).captured;
    final def = captured[0] as ReportDefinition;
    final params = captured[1] as Map<String, String>;

    expect(def.endpoint, '/transactions/reports/balance-sheet');
    expect(params.keys, ['end_date']);
    expect(params['end_date'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
  });
}
