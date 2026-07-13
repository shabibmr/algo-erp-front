import 'package:algo_erp_front/core/reports/report_catalog.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/layout/page_header.dart';
import 'package:algo_erp_front/core/widgets/layout/work_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Catalog of stamped report definitions.
class ReportsHubPage extends StatelessWidget {
  const ReportsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    const reports = ReportCatalog.all;

    return ColoredBox(
      color: brand.linen,
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              eyebrow: 'Reports',
              title: 'Reports',
              subtitle: 'Registers, stock, VAT, and books',
            ),
            SizedBox(height: tokens.spacing.md),
            Expanded(
              child: WorkSheet(
                child: ListView.separated(
                  padding: EdgeInsets.all(tokens.spacing.md),
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => Divider(color: brand.mist),
                  itemBuilder: (context, index) {
                    final r = reports[index];
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: tokens.spacing.sm,
                        vertical: tokens.spacing.xs,
                      ),
                      leading: Icon(
                        Icons.table_chart_outlined,
                        color: brand.lagoon,
                      ),
                      title: Text(r.title),
                      subtitle: Text(
                        r.endpoint,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: brand.inkMuted),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: brand.inkMuted,
                      ),
                      onTap: () => context.go('/reports/${r.id}'),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
