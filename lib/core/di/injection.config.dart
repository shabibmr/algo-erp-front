// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../auth/token_storage.dart' as _i1002;
import '../network/dio_client.dart' as _i667;
import '../network/tenant_context.dart' as _i489;
import '../theme/theme_cubit.dart' as _i611;
import 'register_module.dart' as _i291;

// initializes the registration of main-scope dependencies inside of GetIt
Future<_i174.GetIt> init(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) async {
  final gh = _i526.GetItHelper(getIt, environment, environmentFilter);
  final registerModule = _$RegisterModule();
  await gh.factoryAsync<_i460.SharedPreferences>(
    () => registerModule.prefs,
    preResolve: true,
  );
  gh.singleton<_i489.TenantContext>(() => _i489.TenantContext());
  gh.lazySingleton<_i558.FlutterSecureStorage>(
    () => registerModule.secureStorage,
  );
  gh.lazySingleton<_i1002.TokenStorage>(
    () => _i1002.SecureTokenStorage(gh<_i558.FlutterSecureStorage>()),
  );
  gh.factory<_i611.ThemeCubit>(
    () => _i611.ThemeCubit(gh<_i460.SharedPreferences>()),
  );
  gh.lazySingleton<_i667.DioClient>(
    () => _i667.DioClient(gh<_i1002.TokenStorage>(), gh<_i489.TenantContext>()),
  );
  return getIt;
}

class _$RegisterModule extends _i291.RegisterModule {}
