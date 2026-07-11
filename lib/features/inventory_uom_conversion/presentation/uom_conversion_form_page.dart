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
          final surface = MasterFormSurface<UomConversion, int>(
            manifest: uomConversionManifest,
            mode: mode,
            idOf: (u) => u.id,
            onSaved: (_) => context.go(uomConversionManifest.resourcePath),
            onDeleted: () => context.go(uomConversionManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode == FormMode.create
                      ? 'New ${uomConversionManifest.label}'
                      : 'Edit ${uomConversionManifest.label}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                if (mode == FormMode.edit)
                  BlocProvider<DetailBloc<UomConversion, int>>(
                    create: (ctx) => DetailBloc<UomConversion, int>(
                      repository:
                          ctx.read<Repository<UomConversion, int>>(),
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
