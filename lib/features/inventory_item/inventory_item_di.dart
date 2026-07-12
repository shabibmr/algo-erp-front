import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_item/data/inventory_item_dto.dart';
import 'package:algo_erp_front/features/inventory_item/data/inventory_item_mapper.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:algo_erp_front/features/inventory_item/inventory_item_manifest.dart';

const _inventoryItemMapper = InventoryItemMapper();

RemoteRepository<InventoryItem, int> createInventoryItemRepository(
  DioClient client,
) {
  return buildRepository<InventoryItem, int>(
    client: client,
    resourcePath: inventoryItemManifest.resourcePath,
    decode: (json) =>
        _inventoryItemMapper.toEntity(InventoryItemDto.fromJson(json)),
    encode: (item) => _inventoryItemMapper.toDto(item).toJson(),
    idOf: (item) => item.id,
  );
}

CrudBloc<InventoryItem, int, void> createInventoryItemCrudBloc(
  DioClient client,
) {
  return CrudBloc<InventoryItem, int, void>(
    repository: createInventoryItemRepository(client),
    idOf: (item) => item.id,
  );
}
