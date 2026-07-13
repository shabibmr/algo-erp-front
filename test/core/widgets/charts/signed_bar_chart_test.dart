import 'package:algo_erp_front/core/theme/app_theme.dart';
import 'package:algo_erp_front/core/widgets/charts/signed_bar_chart.dart';
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
  testWidgets('renders one bar group per data group', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SignedBarChart(
          title: 'Sales vs purchase',
          seriesLabels: ['Sales', 'Purchase'],
          seriesColors: [Colors.teal, Colors.brown],
          groups: [
            BarSeriesGroup(label: '2026-05', values: [3, 1]),
            BarSeriesGroup(label: '2026-06', values: [5, 2]),
          ],
        ),
      ),
    );

    expect(find.text('Sales vs purchase'), findsOneWidget);
    final chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(chart.data.barGroups, hasLength(2));
    expect(chart.data.barGroups[0].barRods, hasLength(2));
    expect(find.text('2026-05'), findsOneWidget);
    expect(find.text('2026-06'), findsOneWidget);
    expect(find.textContaining('Sales · 8'), findsOneWidget);
    expect(find.textContaining('Purchase · 3'), findsOneWidget);
  });

  testWidgets('shows empty state when there are no groups', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SignedBarChart(
          title: 'Sales vs purchase',
          seriesLabels: ['Sales', 'Purchase'],
          seriesColors: [Colors.teal, Colors.brown],
          groups: [],
        ),
      ),
    );

    expect(find.byType(BarChart), findsNothing);
    expect(find.text('No data for this period.'), findsOneWidget);
  });
}
