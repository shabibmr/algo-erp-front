import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/organization_audit/audit_log_di.dart';
import 'package:algo_erp_front/features/organization_audit/audit_log_manifest.dart';
import 'package:algo_erp_front/features/organization_audit/domain/audit_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuditLogListPage extends StatelessWidget {
  const AuditLogListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<AuditLog, int, void>>.value(
      value: auditLogCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<AuditLog>(
          manifest: auditLogManifest,
          idOf: (l) => l.id,
          // Read-only trail — no create/edit.
        ),
      ),
    );
  }
}
