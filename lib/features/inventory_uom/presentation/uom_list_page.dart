import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/inventory_uom/domain/uom.dart';
import 'package:algo_erp_front/features/inventory_uom/uom_di.dart';
import 'package:algo_erp_front/features/inventory_uom/uom_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class UomListPage extends StatelessWidget {
  const UomListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<Uom, int, void>>(
      create: (_) => createUomCrudBloc(getIt<DioClient>())
        ..add(const CrudLoadRequested()),
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              uomManifest.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MasterListSurface<Uom>(
                manifest: uomManifest,
                idOf: (uom) => uom.id,
                onCreate: () => context.push('/inventory/uom/new'),
                onTap: (uom) => context.push('/inventory/uom/${uom.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
