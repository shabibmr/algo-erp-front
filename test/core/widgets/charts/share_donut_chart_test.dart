import 'package:algo_erp_front/core/theme/app_theme.dart';
import 'package:algo_erp_front/core/widgets/charts/share_donut_chart.dart';
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
  testWidgets('renders one section per slice and a legend entry each', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const ShareDonutChart(
          title: 'Cash vs bank',
          slices: [
            DonutSlice(label: 'Cash', value: 60, color: Colors.teal),
            DonutSlice(label: 'Bank', value: 40, color: Colors.brown),
          ],
        ),
      ),
    );

    expect(find.text('Cash vs bank'), findsOneWidget);
    final chart = tester.widget<PieChart>(find.byType(PieChart));
    expect(chart.data.sections, hasLength(2));
    expect(find.textContaining('Cash · 60'), findsOneWidget);
    expect(find.textContaining('Bank · 40'), findsOneWidget);
  });

  testWidgets('shows the empty message when slices sum to zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const ShareDonutChart(
          title: 'Cash vs bank',
          slices: [
            DonutSlice(label: 'Cash', value: 0, color: Colors.teal),
            DonutSlice(label: 'Bank', value: 0, color: Colors.brown),
          ],
        ),
      ),
    );

    expect(find.byType(PieChart), findsNothing);
    expect(find.text('No data for this period.'), findsOneWidget);
  });
}
