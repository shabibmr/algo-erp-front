import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_category/category_manifest.dart';
import 'package:algo_erp_front/features/inventory_category/data/category_dto.dart';
import 'package:algo_erp_front/features/inventory_category/data/category_mapper.dart';
import 'package:algo_erp_front/features/inventory_category/domain/category.dart';

const _categoryMapper = CategoryMapper();

RemoteRepository<Category, int> createCategoryRepository(DioClient client) {
  return buildRepository<Category, int>(
    client: client,
    resourcePath: categoryManifest.resourcePath,
    decode: (json) => _categoryMapper.toEntity(CategoryDto.fromJson(json)),
    encode: (c) => _categoryMapper.toDto(c).toJson(),
    idOf: (c) => c.id,
  );
}

CrudBloc<Category, int, void> createCategoryCrudBloc(DioClient client) {
  return CrudBloc<Category, int, void>(
    repository: createCategoryRepository(client),
    idOf: (c) => c.id,
  );
}
