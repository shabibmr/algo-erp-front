import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/charts/chart_legend.dart';
import 'package:algo_erp_front/core/widgets/layout/paper_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// One donut slice.
class DonutSlice {
  const DonutSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

/// A donut/pie chart for part-of-whole breakdowns — e.g. cash vs bank share
/// of liquid position. Colors are supplied by the caller so this widget
/// never hardcodes a palette.
class ShareDonutChart extends StatelessWidget {
  const ShareDonutChart({
    required this.title,
    required this.slices,
    this.valueFormatter,
    this.emptyMessage = 'No data for this period.',
    super.key,
  });

  final String title;
  final List<DonutSlice> slices;
  final String Function(double value)? valueFormatter;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final format = valueFormatter ?? (v) => v.toStringAsFixed(0);
    final total = slices.fold<double>(0, (s, e) => s + e.value.abs());

    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          SizedBox(height: tokens.spacing.md),
          if (slices.isEmpty || total == 0)
            Text(
              emptyMessage,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: brand.inkMuted),
            )
          else ...[
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 42,
                  sections: [
                    for (final slice in slices)
                      PieChartSectionData(
                        value: slice.value.abs(),
                        color: slice.color,
                        title: '',
                        radius: 36,
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: tokens.spacing.sm),
            ChartLegend(
              entries: [
                for (final slice in slices)
                  ChartLegendEntry(
                    color: slice.color,
                    label: slice.label,
                    value: format(slice.value),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
