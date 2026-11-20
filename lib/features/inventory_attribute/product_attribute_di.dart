import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_attribute/data/product_attribute_dto.dart';
import 'package:algo_erp_front/features/inventory_attribute/data/product_attribute_mapper.dart';
import 'package:algo_erp_front/features/inventory_attribute/data/product_attribute_repository.dart';
import 'package:algo_erp_front/features/inventory_attribute/domain/product_attribute.dart';
import 'package:algo_erp_front/features/inventory_attribute/product_attribute_manifest.dart';
import 'package:flutter/widgets.dart';

const _attributeMapper = ProductAttributeMapper();

RemoteRepository<ProductAttribute, int> createProductAttributeRepository(
  DioClient client,
) {
  return buildRepository<ProductAttribute, int>(
    client: client,
    resourcePath: productAttributeManifest.resourcePath,
    decode: (json) =>
        _attributeMapper.toEntity(ProductAttributeDto.fromJson(json)),
    encode: (attr) => _attributeMapper.toDto(attr).toJson(),
    idOf: (attr) => attr.id,
  );
}

CrudBloc<ProductAttribute, int, void> createProductAttributeCrudBloc(
  DioClient client,
) {
  return CrudBloc<ProductAttribute, int, void>(
    repository: createProductAttributeRepository(client),
    idOf: (attr) => attr.id,
  );
}

CrudBloc<ProductAttribute, int, void> productAttributeCrudBloc(
  BuildContext context,
) {
  return CrudBlocScope.of<ProductAttribute, int, void>(
    context,
    productAttributeManifest.id,
    () => createProductAttributeCrudBloc(getIt<DioClient>()),
  );
}

ItemAttributeRepository itemAttributeRepository() =>
    ItemAttributeRepository(getIt<DioClient>());
