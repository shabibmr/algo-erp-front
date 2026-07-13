import 'package:algo_erp_front/core/theme/app_theme.dart';
import 'package:algo_erp_front/core/widgets/charts/ranked_bar_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders one bar per ranked entry', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RankedBarChart(
          title: 'Top customers',
          barColor: Colors.teal,
          entries: [
            RankedBarEntry(label: 'Ledger #1', value: 9),
            RankedBarEntry(label: 'Ledger #2', value: 4),
          ],
        ),
      ),
    );

    expect(find.text('Top customers'), findsOneWidget);
    final chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(chart.data.barGroups, hasLength(2));
    expect(find.text('Ledger #1'), findsOneWidget);
    expect(find.text('Ledger #2'), findsOneWidget);
  });

  testWidgets('shows the empty message when there are no entries', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const RankedBarChart(
          title: 'Top customers',
          barColor: Colors.teal,
          entries: [],
        ),
      ),
    );

    expect(find.byType(BarChart), findsNothing);
    expect(find.text('No data for this period.'), findsOneWidget);
  });
}
