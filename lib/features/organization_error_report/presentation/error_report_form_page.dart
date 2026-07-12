import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/organization_error_report/domain/error_report.dart';
import 'package:algo_erp_front/features/organization_error_report/error_report_di.dart';
import 'package:algo_erp_front/features/organization_error_report/error_report_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Create-only form (no get-by-id on the backend).
class ErrorReportFormPage extends StatelessWidget {
  const ErrorReportFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<ErrorReport, int>>(
      create: (_) => createErrorReportRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          void refreshListAndReturn() {
            errorReportCrudBloc(context).add(const CrudRefreshRequested());
            context.go(errorReportManifest.resourcePath);
          }

          return AdaptiveLayout(
            child: MasterFormSurface<ErrorReport, int>(
              manifest: errorReportManifest,
              mode: FormMode.create,
              idOf: (e) => e.id,
              onSaved: (_) => refreshListAndReturn(),
              onDeleted: refreshListAndReturn,
              onCancel: () => context.go(errorReportManifest.resourcePath),
            ),
          );
        },
      ),
    );
  }
}
