import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/organization_branch/branch_di.dart';
import 'package:algo_erp_front/features/organization_branch/branch_manifest.dart';
import 'package:algo_erp_front/features/organization_branch/domain/branch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class BranchListPage extends StatelessWidget {
  const BranchListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<Branch, int, void>>(
      create: (_) => createBranchCrudBloc(getIt<DioClient>())
        ..add(const CrudLoadRequested()),
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              branchManifest.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MasterListSurface<Branch>(
                manifest: branchManifest,
                idOf: (branch) => branch.id,
                onCreate: () => context.push('/organization/branches/new'),
                onTap: (branch) =>
                    context.push('/organization/branches/${branch.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
