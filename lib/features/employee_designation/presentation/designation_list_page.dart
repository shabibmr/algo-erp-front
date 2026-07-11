import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/employee_designation/designation_di.dart';
import 'package:algo_erp_front/features/employee_designation/designation_manifest.dart';
import 'package:algo_erp_front/features/employee_designation/domain/designation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Designation's list screen — same shape as `BrandListPage`.
class DesignationListPage extends StatelessWidget {
  const DesignationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<Designation, int, void>>(
      create: (_) => createDesignationCrudBloc(getIt<DioClient>())
        ..add(const CrudLoadRequested()),
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              designationManifest.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MasterListSurface<Designation>(
                manifest: designationManifest,
                idOf: (d) => d.id,
                onCreate: () => context.push('/employee/designation/new'),
                onTap: (d) => context.push('/employee/designation/${d.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
