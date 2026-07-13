import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/layout/paper_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// One ranked row — a label and its value.
class RankedBarEntry {
  const RankedBarEntry({required this.label, required this.value});

  final String label;
  final double value;
}

/// A "top N" ranked bar chart — one bar per entry in the order given, one
/// color (from `context.tokens`), used for leaderboards like top customers
/// by invoice count.
class RankedBarChart extends StatelessWidget {
  const RankedBarChart({
    required this.title,
    required this.entries,
    required this.barColor,
    this.valueFormatter,
    this.emptyMessage = 'No data for this period.',
    super.key,
  });

  final String title;
  final List<RankedBarEntry> entries;
  final Color barColor;
  final String Function(double value)? valueFormatter;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final format = valueFormatter ?? (v) => v.toStringAsFixed(0);

    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          SizedBox(height: tokens.spacing.md),
          if (entries.isEmpty)
            Text(
              emptyMessage,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: brand.inkMuted),
            )
          else
            SizedBox(
              height: (entries.length * 32).clamp(80, 220).toDouble(),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      entries
                          .map((e) => e.value)
                          .fold<double>(0, (m, v) => v > m ? v : m) *
                      1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => brand.ink,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                          BarTooltipItem(
                            '${entries[groupIndex].label}\n${format(rod.toY)}',
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
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= entries.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            entries[i].label,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: brand.inkMuted),
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
                    for (var i = 0; i < entries.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: entries[i].value,
                            color: barColor,
                            width: 16,
                            borderRadius: BorderRadius.circular(
                              tokens.radii.sm,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
