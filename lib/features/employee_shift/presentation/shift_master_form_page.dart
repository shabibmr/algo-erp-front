import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/employee_shift/domain/shift_master.dart';
import 'package:algo_erp_front/features/employee_shift/shift_master_di.dart';
import 'package:algo_erp_front/features/employee_shift/shift_master_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ShiftMasterFormPage extends StatelessWidget {
  const ShiftMasterFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<ShiftMaster, int>>(
      create: (_) => createShiftMasterRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          void refreshListAndReturn() {
            shiftMasterCrudBloc(context).add(const CrudRefreshRequested());
            context.go(shiftMasterManifest.resourcePath);
          }

          final surface = MasterFormSurface<ShiftMaster, int>(
            manifest: shiftMasterManifest,
            mode: mode,
            idOf: (s) => s.id,
            onSaved: (_) => refreshListAndReturn(),
            onDeleted: refreshListAndReturn,
            onCancel: () => context.go(shiftMasterManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: mode == FormMode.edit
                ? BlocProvider<DetailBloc<ShiftMaster, int>>(
                    create: (ctx) => DetailBloc<ShiftMaster, int>(
                      repository: ctx.read<Repository<ShiftMaster, int>>(),
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
