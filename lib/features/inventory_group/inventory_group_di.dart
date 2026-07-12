import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_group/data/inventory_group_dto.dart';
import 'package:algo_erp_front/features/inventory_group/data/inventory_group_mapper.dart';
import 'package:algo_erp_front/features/inventory_group/domain/inventory_group.dart';
import 'package:flutter/widgets.dart';

const _inventoryGroupMapper = InventoryGroupMapper();

/// Path kept as a literal so this DI file can be imported by the selfFk
/// parent picker in the manifest without a circular import.
const inventoryGroupResourcePath = '/inventory/group';

RemoteRepository<InventoryGroup, int> createInventoryGroupRepository(
  DioClient client,
) {
  return buildRepository<InventoryGroup, int>(
    client: client,
    resourcePath: inventoryGroupResourcePath,
    decode: (json) =>
        _inventoryGroupMapper.toEntity(InventoryGroupDto.fromJson(json)),
    encode: (group) => _inventoryGroupMapper.toDto(group).toJson(),
    idOf: (group) => group.id,
  );
}

CrudBloc<InventoryGroup, int, void> createInventoryGroupCrudBloc(
  DioClient client,
) {
  return CrudBloc<InventoryGroup, int, void>(
    repository: createInventoryGroupRepository(client),
    idOf: (group) => group.id,
  );
}

/// The one InventoryGroup [CrudBloc], shared by the list and form routes via
/// the [CrudBlocScope] in `AppShell`. Both pages must go through this —
/// resolving the bloc any other way gives the form a private instance the list
/// never sees, which is how created rows went missing.
///
/// Keyed by [inventoryGroupResourcePath] rather than the manifest id, because
/// this file deliberately does not import the manifest (see above).
CrudBloc<InventoryGroup, int, void> inventoryGroupCrudBloc(
  BuildContext context,
) {
  return CrudBlocScope.of<InventoryGroup, int, void>(
    context,
    inventoryGroupResourcePath,
    () => createInventoryGroupCrudBloc(getIt<DioClient>()),
  );
}
