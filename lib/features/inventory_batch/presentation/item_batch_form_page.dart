import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/inventory_batch/domain/item_batch.dart';
import 'package:algo_erp_front/features/inventory_batch/item_batch_di.dart';
import 'package:algo_erp_front/features/inventory_batch/item_batch_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ItemBatchFormPage extends StatelessWidget {
  const ItemBatchFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<ItemBatch, int>>(
      create: (_) => createItemBatchRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          final surface = MasterFormSurface<ItemBatch, int>(
            manifest: itemBatchManifest,
            mode: mode,
            idOf: (b) => b.id,
            onSaved: (_) => context.go(itemBatchManifest.resourcePath),
            onDeleted: () => context.go(itemBatchManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode == FormMode.create
                      ? 'New ${itemBatchManifest.label}'
                      : itemBatchManifest.supportsUpdate
                          ? 'Edit ${itemBatchManifest.label}'
                          : 'View ${itemBatchManifest.label}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                if (mode == FormMode.edit)
                  BlocProvider<DetailBloc<ItemBatch, int>>(
                    create: (ctx) => DetailBloc<ItemBatch, int>(
                      repository: ctx.read<Repository<ItemBatch, int>>(),
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
