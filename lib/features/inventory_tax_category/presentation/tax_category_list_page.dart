import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/inventory_tax_category/domain/tax_category.dart';
import 'package:algo_erp_front/features/inventory_tax_category/tax_category_di.dart';
import 'package:algo_erp_front/features/inventory_tax_category/tax_category_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class TaxCategoryListPage extends StatelessWidget {
  const TaxCategoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // `.value`, not `create:` — the bloc is owned by the CrudBlocScope
    // in AppShell so the form route shares it. See taxCategoryCrudBloc.
    return BlocProvider<CrudBloc<TaxCategory, int, void>>.value(
      value: taxCategoryCrudBloc(context),
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              taxCategoryManifest.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MasterListSurface<TaxCategory>(
                manifest: taxCategoryManifest,
                idOf: (t) => t.id,
                onCreate: () => context.push('/inventory/tax-category/new'),
                onTap: (t) => context.push('/inventory/tax-category/${t.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
