import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/charts/chart_legend.dart';
import 'package:algo_erp_front/core/widgets/layout/paper_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// One x-axis group (e.g. a month) with one value per series.
class BarSeriesGroup {
  const BarSeriesGroup({required this.label, required this.values});

  final String label;

  /// One value per series, same order/length as [SignedBarChart.seriesLabels].
  final List<double> values;
}

/// A grouped bar chart for comparing 1+ series across a set of x-axis
/// groups — e.g. sales vs purchase invoice counts, month over month.
/// Colors are supplied by the caller (from `context.tokens`) so this widget
/// never hardcodes a palette.
class SignedBarChart extends StatelessWidget {
  const SignedBarChart({
    required this.title,
    required this.seriesLabels,
    required this.seriesColors,
    required this.groups,
    this.valueFormatter,
    super.key,
  });

  final String title;
  final List<String> seriesLabels;
  final List<Color> seriesColors;
  final List<BarSeriesGroup> groups;
  final String Function(double value)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    assert(
      seriesLabels.length == seriesColors.length,
      'seriesLabels and seriesColors must be the same length',
    );
    final tokens = context.tokens;
    final brand = tokens.brand;
    final format = valueFormatter ?? (v) => v.toStringAsFixed(0);

    if (groups.isEmpty) {
      return PaperCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            SizedBox(height: tokens.spacing.sm),
            Text(
              'No data for this period.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: brand.inkMuted),
            ),
          ],
        ),
      );
    }

    final maxY = groups
        .expand((g) => g.values)
        .fold<double>(0, (m, v) => v > m ? v : m);
    final totals = List<double>.filled(seriesLabels.length, 0);
    for (final g in groups) {
      for (var i = 0; i < g.values.length; i++) {
        totals[i] += g.values[i];
      }
    }

    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          SizedBox(height: tokens.spacing.md),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxY <= 0 ? 1 : maxY * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => brand.ink,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                          '${seriesLabels[rodIndex]}\n${format(rod.toY)}',
                          TextStyle(color: brand.paper, fontSize: 12),
                        ),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= groups.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: EdgeInsets.only(top: tokens.spacing.xs),
                          child: Text(
                            groups[i].label,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: brand.inkMuted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: brand.mist, strokeWidth: 1),
                ),
                barGroups: [
                  for (var i = 0; i < groups.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        for (var s = 0; s < seriesLabels.length; s++)
                          BarChartRodData(
                            toY: groups[i].values[s],
                            color: seriesColors[s],
                            width: seriesLabels.length > 1 ? 8 : 14,
                            borderRadius: BorderRadius.circular(
                              tokens.radii.sm,
                            ),
                          ),
                      ],
                      barsSpace: 4,
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: tokens.spacing.sm),
          ChartLegend(
            entries: [
              for (var i = 0; i < seriesLabels.length; i++)
                ChartLegendEntry(
                  color: seriesColors[i],
                  label: seriesLabels[i],
                  value: format(totals[i]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
