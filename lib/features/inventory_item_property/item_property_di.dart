import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_item_property/data/item_property_dto.dart';
import 'package:algo_erp_front/features/inventory_item_property/data/item_property_mapper.dart';
import 'package:algo_erp_front/features/inventory_item_property/domain/item_property.dart';
import 'package:algo_erp_front/features/inventory_item_property/item_property_manifest.dart';

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

CrudBloc<ItemProperty, int, void> createItemPropertyCrudBloc(
  DioClient client,
) {
  return CrudBloc<ItemProperty, int, void>(
    repository: createItemPropertyRepository(client),
    idOf: (property) => property.id,
  );
}
