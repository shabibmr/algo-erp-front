import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/inventory_route/domain/route_master.dart';
import 'package:algo_erp_front/features/inventory_route/route_master_di.dart';
import 'package:algo_erp_front/features/inventory_route/route_master_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RouteMasterListPage extends StatelessWidget {
  const RouteMasterListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<RouteMaster, int, void>>(
      create: (_) => createRouteMasterCrudBloc(getIt<DioClient>())
        ..add(const CrudLoadRequested()),
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              routeMasterManifest.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MasterListSurface<RouteMaster>(
                manifest: routeMasterManifest,
                idOf: (r) => r.id,
                onCreate: () => context.push('/inventory/route/new'),
                onTap: (r) => context.push('/inventory/route/${r.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
