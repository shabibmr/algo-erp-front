import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/inventory_uom_conversion/domain/uom_conversion.dart';
import 'package:algo_erp_front/features/inventory_uom_conversion/uom_conversion_di.dart';
import 'package:algo_erp_front/features/inventory_uom_conversion/uom_conversion_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class UomConversionFormPage extends StatelessWidget {
  const UomConversionFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<UomConversion, int>>(
      create: (_) => createUomConversionRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          // The surface has already persisted through the repository by the
          // time these fire, so the shared list bloc is told to refetch —
          // never CrudItemCreated/Updated/Deleted, which would write again.
          void refreshListAndReturn() {
            uomConversionCrudBloc(context).add(const CrudRefreshRequested());
            context.go(uomConversionManifest.resourcePath);
          }

          final surface = MasterFormSurface<UomConversion, int>(
            manifest: uomConversionManifest,
            mode: mode,
            idOf: (u) => u.id,
            onSaved: (_) => refreshListAndReturn(),
            onDeleted: refreshListAndReturn,
          );
          return AdaptiveLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode == FormMode.create
                      ? 'New ${uomConversionManifest.label}'
                      : uomConversionManifest.supportsUpdate
                      ? 'Edit ${uomConversionManifest.label}'
                      : 'View ${uomConversionManifest.label}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                if (mode == FormMode.edit)
                  BlocProvider<DetailBloc<UomConversion, int>>(
                    create: (ctx) => DetailBloc<UomConversion, int>(
                      repository: ctx.read<Repository<UomConversion, int>>(),
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
