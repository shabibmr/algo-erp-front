import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/employee_leave_policy/domain/leave_policy.dart';
import 'package:algo_erp_front/features/employee_leave_policy/leave_policy_di.dart';
import 'package:algo_erp_front/features/employee_leave_policy/leave_policy_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LeavePolicyFormPage extends StatelessWidget {
  const LeavePolicyFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<LeavePolicy, int>>(
      create: (_) => createLeavePolicyRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          void refreshListAndReturn() {
            leavePolicyCrudBloc(context).add(const CrudRefreshRequested());
            context.go(leavePolicyManifest.resourcePath);
          }

          final surface = MasterFormSurface<LeavePolicy, int>(
            manifest: leavePolicyManifest,
            mode: mode,
            idOf: (p) => p.id,
            onSaved: (_) => refreshListAndReturn(),
            onDeleted: refreshListAndReturn,
            onCancel: () => context.go(leavePolicyManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: mode == FormMode.edit
                ? BlocProvider<DetailBloc<LeavePolicy, int>>(
                    create: (ctx) => DetailBloc<LeavePolicy, int>(
                      repository: ctx.read<Repository<LeavePolicy, int>>(),
                      id: entityId!,
                    )..add(const DetailLoadRequested()),
                    child: surface,
                  )
                : surface,
          );
        },
      ),
    );
  }
}
