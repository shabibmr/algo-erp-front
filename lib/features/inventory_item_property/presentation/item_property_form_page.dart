import 'package:algo_erp_front/core/bloc/crud_contract.dart';
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
          // The surface has already persisted through the repository by the
          // time these fire, so the shared list bloc is told to refetch —
          // never CrudItemCreated/Updated/Deleted, which would write again.
          void refreshListAndReturn() {
            itemPropertyCrudBloc(context).add(const CrudRefreshRequested());
            context.go(itemPropertyManifest.resourcePath);
          }

          final surface = MasterFormSurface<ItemProperty, int>(
            manifest: itemPropertyManifest,
            mode: mode,
            idOf: (property) => property.id,
            onSaved: (_) => refreshListAndReturn(),
            onDeleted: refreshListAndReturn,
          );
          return AdaptiveLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode == FormMode.create
                      ? 'New ${itemPropertyManifest.label}'
                      : itemPropertyManifest.supportsUpdate
                      ? 'Edit ${itemPropertyManifest.label}'
                      : 'View ${itemPropertyManifest.label}',
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
