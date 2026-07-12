import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_item/data/inventory_item_dto.dart';
import 'package:algo_erp_front/features/inventory_item/data/inventory_item_mapper.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:algo_erp_front/features/inventory_item/inventory_item_manifest.dart';
import 'package:flutter/widgets.dart';

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

/// The one InventoryItem [CrudBloc], shared by the list and form routes via the
/// [CrudBlocScope] in `AppShell`. Both pages must go through this —
/// resolving the bloc any other way gives the form a private instance the
/// list never sees, which is how created rows went missing.
CrudBloc<InventoryItem, int, void> inventoryItemCrudBloc(BuildContext context) {
  return CrudBlocScope.of<InventoryItem, int, void>(
    context,
    inventoryItemManifest.id,
    () => createInventoryItemCrudBloc(getIt<DioClient>()),
  );
}
