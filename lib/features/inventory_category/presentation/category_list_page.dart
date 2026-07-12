import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/inventory_category/category_di.dart';
import 'package:algo_erp_front/features/inventory_category/category_manifest.dart';
import 'package:algo_erp_front/features/inventory_category/domain/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CategoryListPage extends StatelessWidget {
  const CategoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // `.value`, not `create:` — the bloc is owned by the CrudBlocScope
    // in AppShell so the form route shares it. See categoryCrudBloc.
    return BlocProvider<CrudBloc<Category, int, void>>.value(
      value: categoryCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<Category>(
          manifest: categoryManifest,
          idOf: (c) => c.id,
          onCreate: () => context.push('/inventory/category/new'),
          onTap: (c) => context.push('/inventory/category/${c.id}'),
        ),
      ),
    );
  }
}
