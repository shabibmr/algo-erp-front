import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_item_property/data/item_property_dto.dart';
import 'package:algo_erp_front/features/inventory_item_property/data/item_property_mapper.dart';
import 'package:algo_erp_front/features/inventory_item_property/domain/item_property.dart';
import 'package:algo_erp_front/features/inventory_item_property/item_property_manifest.dart';
import 'package:flutter/widgets.dart';

const _itemPropertyMapper = ItemPropertyMapper();

RemoteRepository<ItemProperty, int> createItemPropertyRepository(
  DioClient client,
) {
  return buildRepository<ItemProperty, int>(
    client: client,
    resourcePath: itemPropertyManifest.resourcePath,
    decode: (json) =>
        _itemPropertyMapper.toEntity(ItemPropertyDto.fromJson(json)),
    encode: (property) => _itemPropertyMapper.toDto(property).toJson(),
    idOf: (property) => property.id,
  );
}

CrudBloc<ItemProperty, int, void> createItemPropertyCrudBloc(DioClient client) {
  return CrudBloc<ItemProperty, int, void>(
    repository: createItemPropertyRepository(client),
    idOf: (property) => property.id,
  );
}

/// The one ItemProperty [CrudBloc], shared by the list and form routes via the
/// [CrudBlocScope] in `AppShell`. Both pages must go through this —
/// resolving the bloc any other way gives the form a private instance the
/// list never sees, which is how created rows went missing.
CrudBloc<ItemProperty, int, void> itemPropertyCrudBloc(BuildContext context) {
  return CrudBlocScope.of<ItemProperty, int, void>(
    context,
    itemPropertyManifest.id,
    () => createItemPropertyCrudBloc(getIt<DioClient>()),
  );
}
