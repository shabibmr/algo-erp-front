import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/organization_error_report/domain/error_report.dart';
import 'package:algo_erp_front/features/organization_error_report/error_report_di.dart';
import 'package:algo_erp_front/features/organization_error_report/error_report_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ErrorReportListPage extends StatelessWidget {
  const ErrorReportListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<ErrorReport, int, void>>.value(
      value: errorReportCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<ErrorReport>(
          manifest: errorReportManifest,
          idOf: (e) => e.id,
          onCreate: () => context.push('/organization/error-reports/new'),
        ),
      ),
    );
  }
}
