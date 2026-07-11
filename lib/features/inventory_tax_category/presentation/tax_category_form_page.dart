import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/inventory_tax_category/domain/tax_category.dart';
import 'package:algo_erp_front/features/inventory_tax_category/tax_category_di.dart';
import 'package:algo_erp_front/features/inventory_tax_category/tax_category_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class TaxCategoryFormPage extends StatelessWidget {
  const TaxCategoryFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<TaxCategory, int>>(
      create: (_) => createTaxCategoryRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          final surface = MasterFormSurface<TaxCategory, int>(
            manifest: taxCategoryManifest,
            mode: mode,
            idOf: (t) => t.id,
            onSaved: (_) => context.go(taxCategoryManifest.resourcePath),
            onDeleted: () => context.go(taxCategoryManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode == FormMode.create
                      ? 'New ${taxCategoryManifest.label}'
                      : taxCategoryManifest.supportsUpdate
                          ? 'Edit ${taxCategoryManifest.label}'
                          : 'View ${taxCategoryManifest.label}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                if (mode == FormMode.edit)
                  BlocProvider<DetailBloc<TaxCategory, int>>(
                    create: (ctx) => DetailBloc<TaxCategory, int>(
                      repository: ctx.read<Repository<TaxCategory, int>>(),
                      id: entityId!,
                    )..add(const DetailLoadRequested()),
                    child: surface,
                  )
                else
                  surface,
              ],
            ),
          );
        },
      ),
    );
  }
}
