import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_group/data/inventory_group_dto.dart';
import 'package:algo_erp_front/features/inventory_group/data/inventory_group_mapper.dart';
import 'package:algo_erp_front/features/inventory_group/domain/inventory_group.dart';

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
