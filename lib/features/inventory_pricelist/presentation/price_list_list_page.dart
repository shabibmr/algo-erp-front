import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/inventory_pricelist/domain/price_list.dart';
import 'package:algo_erp_front/features/inventory_pricelist/price_list_di.dart';
import 'package:algo_erp_front/features/inventory_pricelist/price_list_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PriceListListPage extends StatelessWidget {
  const PriceListListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<PriceList, int, void>>(
      create: (_) => createPriceListCrudBloc(getIt<DioClient>())
        ..add(const CrudLoadRequested()),
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              priceListManifest.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MasterListSurface<PriceList>(
                manifest: priceListManifest,
                idOf: (p) => p.id,
                onCreate: () => context.push('/inventory/pricelist/new'),
                onTap: (p) => context.push('/inventory/pricelist/${p.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
