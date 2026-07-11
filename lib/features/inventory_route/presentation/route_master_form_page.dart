import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/inventory_route/domain/route_master.dart';
import 'package:algo_erp_front/features/inventory_route/route_master_di.dart';
import 'package:algo_erp_front/features/inventory_route/route_master_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RouteMasterFormPage extends StatelessWidget {
  const RouteMasterFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<RouteMaster, int>>(
      create: (_) => createRouteMasterRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          final surface = MasterFormSurface<RouteMaster, int>(
            manifest: routeMasterManifest,
            mode: mode,
            idOf: (r) => r.id,
            onSaved: (_) => context.go(routeMasterManifest.resourcePath),
            onDeleted: () => context.go(routeMasterManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode == FormMode.create
                      ? 'New ${routeMasterManifest.label}'
                      : routeMasterManifest.supportsUpdate
                          ? 'Edit ${routeMasterManifest.label}'
                          : 'View ${routeMasterManifest.label}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                if (mode == FormMode.edit)
                  BlocProvider<DetailBloc<RouteMaster, int>>(
                    create: (ctx) => DetailBloc<RouteMaster, int>(
                      repository: ctx.read<Repository<RouteMaster, int>>(),
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
