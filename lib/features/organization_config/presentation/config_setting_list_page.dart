import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/organization_config/config_setting_di.dart';
import 'package:algo_erp_front/features/organization_config/config_setting_manifest.dart';
import 'package:algo_erp_front/features/organization_config/domain/config_setting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ConfigSettingListPage extends StatelessWidget {
  const ConfigSettingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<ConfigSetting, int, void>>.value(
      value: configSettingCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<ConfigSetting>(
          manifest: configSettingManifest,
          idOf: (s) => s.id,
          // Create is not supported (seeded server-side only).
          onTap: (s) => context.push('/organization/config/${s.id}'),
        ),
      ),
    );
  }
}
