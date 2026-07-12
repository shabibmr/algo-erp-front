import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/employee_shift/domain/shift_master.dart';
import 'package:algo_erp_front/features/employee_shift/shift_master_di.dart';
import 'package:algo_erp_front/features/employee_shift/shift_master_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ShiftMasterListPage extends StatelessWidget {
  const ShiftMasterListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<ShiftMaster, int, void>>.value(
      value: shiftMasterCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<ShiftMaster>(
          manifest: shiftMasterManifest,
          idOf: (s) => s.id,
          onCreate: () => context.push('/employee/shifts/new'),
          onTap: (s) => context.push('/employee/shifts/${s.id}'),
        ),
      ),
    );
  }
}
