import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/organization_config/config_setting_di.dart';
import 'package:algo_erp_front/features/organization_config/config_setting_manifest.dart';
import 'package:algo_erp_front/features/organization_config/domain/config_setting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ConfigSettingFormPage extends StatelessWidget {
  const ConfigSettingFormPage({required this.entityId, super.key});

  final int entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<ConfigSetting, int>>(
      create: (_) => createConfigSettingRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          void refreshListAndReturn() {
            configSettingCrudBloc(context).add(const CrudRefreshRequested());
            context.go(configSettingManifest.resourcePath);
          }

          final surface = MasterFormSurface<ConfigSetting, int>(
            manifest: configSettingManifest,
            mode: FormMode.edit,
            idOf: (s) => s.id,
            onSaved: (_) => refreshListAndReturn(),
            onDeleted: refreshListAndReturn,
            onCancel: () => context.go(configSettingManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: BlocProvider<DetailBloc<ConfigSetting, int>>(
              create: (ctx) => DetailBloc<ConfigSetting, int>(
                repository: ctx.read<Repository<ConfigSetting, int>>(),
                id: entityId,
              )..add(const DetailLoadRequested()),
              child: surface,
            ),
          );
        },
      ),
    );
  }
}
