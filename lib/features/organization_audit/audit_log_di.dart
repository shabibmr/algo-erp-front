import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/organization_audit/audit_log_manifest.dart';
import 'package:algo_erp_front/features/organization_audit/data/audit_log_repository.dart';
import 'package:algo_erp_front/features/organization_audit/domain/audit_log.dart';
import 'package:flutter/widgets.dart';

Repository<AuditLog, int> createAuditLogRepository(DioClient client) {
  return AuditLogRepository(client);
}

CrudBloc<AuditLog, int, void> createAuditLogCrudBloc(DioClient client) {
  return CrudBloc<AuditLog, int, void>(
    repository: createAuditLogRepository(client),
    idOf: (l) => l.id,
  );
}

CrudBloc<AuditLog, int, void> auditLogCrudBloc(BuildContext context) {
  return CrudBlocScope.of<AuditLog, int, void>(
    context,
    auditLogManifest.id,
    () => createAuditLogCrudBloc(getIt<DioClient>()),
  );
}
