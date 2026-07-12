import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/inventory_sku/domain/sku_master.dart';
import 'package:algo_erp_front/features/inventory_sku/sku_master_di.dart';
import 'package:algo_erp_front/features/inventory_sku/sku_master_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SkuMasterListPage extends StatelessWidget {
  const SkuMasterListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<SkuMaster, int, void>>(
      create: (_) => createSkuMasterCrudBloc(getIt<DioClient>())
        ..add(const CrudLoadRequested()),
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              skuMasterManifest.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MasterListSurface<SkuMaster>(
                manifest: skuMasterManifest,
                idOf: (s) => s.id,
                onCreate: () => context.push('/inventory/sku/new'),
                onTap: (s) => context.push('/inventory/sku/${s.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
