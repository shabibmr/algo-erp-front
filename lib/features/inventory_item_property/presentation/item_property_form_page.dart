import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/inventory_item_property/domain/item_property.dart';
import 'package:algo_erp_front/features/inventory_item_property/item_property_di.dart';
import 'package:algo_erp_front/features/inventory_item_property/item_property_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ItemPropertyFormPage extends StatelessWidget {
  const ItemPropertyFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<ItemProperty, int>>(
      create: (_) => createItemPropertyRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          final surface = MasterFormSurface<ItemProperty, int>(
            manifest: itemPropertyManifest,
            mode: mode,
            idOf: (property) => property.id,
            onSaved: (_) => context.go(itemPropertyManifest.resourcePath),
            onDeleted: () => context.go(itemPropertyManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode == FormMode.create
                      ? 'New ${itemPropertyManifest.label}'
                      : 'Edit ${itemPropertyManifest.label}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                if (mode == FormMode.edit)
                  BlocProvider<DetailBloc<ItemProperty, int>>(
                    create: (ctx) => DetailBloc<ItemProperty, int>(
                      repository: ctx.read<Repository<ItemProperty, int>>(),
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
