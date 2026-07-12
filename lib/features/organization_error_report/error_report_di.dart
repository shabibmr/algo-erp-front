import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/organization_error_report/data/error_report_repository.dart';
import 'package:algo_erp_front/features/organization_error_report/domain/error_report.dart';
import 'package:algo_erp_front/features/organization_error_report/error_report_manifest.dart';
import 'package:flutter/widgets.dart';

Repository<ErrorReport, int> createErrorReportRepository(DioClient client) {
  return ErrorReportRepository(client);
}

CrudBloc<ErrorReport, int, void> createErrorReportCrudBloc(DioClient client) {
  return CrudBloc<ErrorReport, int, void>(
    repository: createErrorReportRepository(client),
    idOf: (e) => e.id,
  );
}

CrudBloc<ErrorReport, int, void> errorReportCrudBloc(BuildContext context) {
  return CrudBlocScope.of<ErrorReport, int, void>(
    context,
    errorReportManifest.id,
    () => createErrorReportCrudBloc(getIt<DioClient>()),
  );
}
