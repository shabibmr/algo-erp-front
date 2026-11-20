import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/inventory_attribute/domain/product_attribute.dart';
import 'package:algo_erp_front/features/inventory_attribute/product_attribute_di.dart';
import 'package:algo_erp_front/features/inventory_attribute/product_attribute_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProductAttributeListPage extends StatelessWidget {
  const ProductAttributeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<ProductAttribute, int, void>>.value(
      value: productAttributeCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<ProductAttribute>(
          manifest: productAttributeManifest,
          idOf: (attr) => attr.id,
          onCreate: () => context.push('/inventory/attribute/new'),
          onTap: (attr) => context.push('/inventory/attribute/${attr.id}'),
        ),
      ),
    );
  }
}
