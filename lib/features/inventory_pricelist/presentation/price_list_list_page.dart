import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
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
    // `.value`, not `create:` — the bloc is owned by the CrudBlocScope
    // in AppShell so the form route shares it. See priceListCrudBloc.
    return BlocProvider<CrudBloc<PriceList, int, void>>.value(
      value: priceListCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<PriceList>(
          manifest: priceListManifest,
          idOf: (p) => p.id,
          onCreate: () => context.push('/inventory/pricelist/new'),
          onTap: (p) => context.push('/inventory/pricelist/${p.id}'),
        ),
      ),
    );
  }
}
