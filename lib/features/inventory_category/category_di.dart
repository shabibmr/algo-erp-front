import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_category/category_manifest.dart';
import 'package:algo_erp_front/features/inventory_category/data/category_dto.dart';
import 'package:algo_erp_front/features/inventory_category/data/category_mapper.dart';
import 'package:algo_erp_front/features/inventory_category/domain/category.dart';
import 'package:flutter/widgets.dart';

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

/// The one Category [CrudBloc], shared by the list and form routes via the
/// [CrudBlocScope] in `AppShell`. Both pages must go through this —
/// resolving the bloc any other way gives the form a private instance the
/// list never sees, which is how created rows went missing.
CrudBloc<Category, int, void> categoryCrudBloc(BuildContext context) {
  return CrudBlocScope.of<Category, int, void>(
    context,
    categoryManifest.id,
    () => createCategoryCrudBloc(getIt<DioClient>()),
  );
}
