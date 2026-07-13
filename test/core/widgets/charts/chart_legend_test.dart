import 'package:algo_erp_front/core/theme/app_theme.dart';
import 'package:algo_erp_front/core/widgets/charts/chart_legend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders label and value for each entry', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ChartLegend(
          entries: [
            ChartLegendEntry(color: Colors.red, label: 'Sales', value: '12'),
            ChartLegendEntry(color: Colors.blue, label: 'Purchase', value: '5'),
          ],
        ),
      ),
    );

    expect(find.text('Sales · 12'), findsOneWidget);
    expect(find.text('Purchase · 5'), findsOneWidget);
  });

  testWidgets('renders label alone when value is omitted', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ChartLegend(
          entries: [ChartLegendEntry(color: Colors.green, label: 'Cash')],
        ),
      ),
    );

    expect(find.text('Cash'), findsOneWidget);
  });
}
