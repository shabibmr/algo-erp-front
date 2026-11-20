import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/inventory_attribute/domain/product_attribute.dart';
import 'package:algo_erp_front/features/inventory_attribute/product_attribute_di.dart';
import 'package:algo_erp_front/features/inventory_attribute/product_attribute_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProductAttributeFormPage extends StatelessWidget {
  const ProductAttributeFormPage({
    required this.mode,
    super.key,
    this.entityId,
  });

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<ProductAttribute, int>>(
      create: (_) => createProductAttributeRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          void refreshListAndReturn() {
            productAttributeCrudBloc(context).add(const CrudRefreshRequested());
            context.go(productAttributeManifest.resourcePath);
          }

          final surface = MasterFormSurface<ProductAttribute, int>(
            manifest: productAttributeManifest,
            mode: mode,
            idOf: (attr) => attr.id,
            onSaved: (_) => refreshListAndReturn(),
            onDeleted: refreshListAndReturn,
            onCancel: () => context.go(productAttributeManifest.resourcePath),
          );

          return AdaptiveLayout(
            child: mode == FormMode.edit
                ? BlocProvider<DetailBloc<ProductAttribute, int>>(
                    create: (ctx) => DetailBloc<ProductAttribute, int>(
                      repository: ctx.read<Repository<ProductAttribute, int>>(),
                      id: entityId!,
                    )..add(const DetailLoadRequested()),
                    child: surface,
                  )
                : surface,
          );
        },
      ),
    );
  }
}
