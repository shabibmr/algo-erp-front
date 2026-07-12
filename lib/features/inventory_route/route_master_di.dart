import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_route/data/route_master_dto.dart';
import 'package:algo_erp_front/features/inventory_route/data/route_master_mapper.dart';
import 'package:algo_erp_front/features/inventory_route/domain/route_master.dart';
import 'package:algo_erp_front/features/inventory_route/route_master_manifest.dart';
import 'package:flutter/widgets.dart';

const _routeMasterMapper = RouteMasterMapper();

RemoteRepository<RouteMaster, int> createRouteMasterRepository(
  DioClient client,
) {
  return buildRepository<RouteMaster, int>(
    client: client,
    resourcePath: routeMasterManifest.resourcePath,
    decode: (json) =>
        _routeMasterMapper.toEntity(RouteMasterDto.fromJson(json)),
    encode: (r) => _routeMasterMapper.toDto(r).toJson(),
    idOf: (r) => r.id,
  );
}

CrudBloc<RouteMaster, int, void> createRouteMasterCrudBloc(DioClient client) {
  return CrudBloc<RouteMaster, int, void>(
    repository: createRouteMasterRepository(client),
    idOf: (r) => r.id,
  );
}

/// The one RouteMaster [CrudBloc], shared by the list and form routes via the
/// [CrudBlocScope] in `AppShell`. Both pages must go through this —
/// resolving the bloc any other way gives the form a private instance the
/// list never sees, which is how created rows went missing.
CrudBloc<RouteMaster, int, void> routeMasterCrudBloc(BuildContext context) {
  return CrudBlocScope.of<RouteMaster, int, void>(
    context,
    routeMasterManifest.id,
    () => createRouteMasterCrudBloc(getIt<DioClient>()),
  );
}
