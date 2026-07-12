import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/organization_config/config_setting_manifest.dart';
import 'package:algo_erp_front/features/organization_config/data/config_setting_repository.dart';
import 'package:algo_erp_front/features/organization_config/domain/config_setting.dart';
import 'package:flutter/widgets.dart';

Repository<ConfigSetting, int> createConfigSettingRepository(DioClient client) {
  return ConfigSettingRepository(client);
}

CrudBloc<ConfigSetting, int, void> createConfigSettingCrudBloc(
  DioClient client,
) {
  return CrudBloc<ConfigSetting, int, void>(
    repository: createConfigSettingRepository(client),
    idOf: (s) => s.id,
  );
}

CrudBloc<ConfigSetting, int, void> configSettingCrudBloc(BuildContext context) {
  return CrudBlocScope.of<ConfigSetting, int, void>(
    context,
    configSettingManifest.id,
    () => createConfigSettingCrudBloc(getIt<DioClient>()),
  );
}
