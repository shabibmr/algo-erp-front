import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:flutter/material.dart';

/// One legend entry: a color dot, a label, and (optionally) a formatted
/// value — shown under/beside a chart so a color always resolves to a name.
class ChartLegendEntry {
  const ChartLegendEntry({
    required this.color,
    required this.label,
    this.value,
  });

  final Color color;
  final String label;
  final String? value;
}

/// A wrapping row of [ChartLegendEntry]s. Shared by every chart in
/// `core/widgets/charts/` so series color-to-label mapping always reads the
/// same way across the dashboard.
class ChartLegend extends StatelessWidget {
  const ChartLegend({required this.entries, super.key});

  final List<ChartLegendEntry> entries;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    return Wrap(
      spacing: tokens.spacing.md,
      runSpacing: tokens.spacing.xs,
      children: [
        for (final entry in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: entry.color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: tokens.spacing.xs),
              Text(
                entry.value == null
                    ? entry.label
                    : '${entry.label} · ${entry.value}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: brand.inkMuted),
              ),
            ],
          ),
      ],
    );
  }
}
