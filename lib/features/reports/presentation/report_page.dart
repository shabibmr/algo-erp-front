import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/reports/report_catalog.dart';
import 'package:algo_erp_front/core/reports/report_repository.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/report_viewer.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/states/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({required this.reportId, super.key});

  final String reportId;

  @override
  Widget build(BuildContext context) {
    final def = ReportCatalog.byId(reportId);
    final tokens = context.tokens;
    final gradient = tokens.gradient.canvasGradient;

    if (def == null) {
      return DecoratedBox(
        decoration: BoxDecoration(gradient: gradient),
        child: AdaptiveLayout(
          child: EmptyState(
            message: 'Unknown report: $reportId',
            icon: Icons.search_off_outlined,
            actionLabel: 'Back to reports',
            onAction: () => context.go('/reports'),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: AdaptiveLayout(
        child: ReportViewer(
          definition: def,
          repository: createReportRepository(getIt<DioClient>()),
        ),
      ),
    );
  }
}
