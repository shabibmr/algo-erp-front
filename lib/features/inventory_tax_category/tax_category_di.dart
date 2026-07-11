import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_tax_category/data/tax_category_dto.dart';
import 'package:algo_erp_front/features/inventory_tax_category/data/tax_category_mapper.dart';
import 'package:algo_erp_front/features/inventory_tax_category/domain/tax_category.dart';
import 'package:algo_erp_front/features/inventory_tax_category/tax_category_manifest.dart';

const _taxCategoryMapper = TaxCategoryMapper();

RemoteRepository<TaxCategory, int> createTaxCategoryRepository(
  DioClient client,
) {
  return buildRepository<TaxCategory, int>(
    client: client,
    resourcePath: taxCategoryManifest.resourcePath,
    decode: (json) =>
        _taxCategoryMapper.toEntity(TaxCategoryDto.fromJson(json)),
    encode: (t) => _taxCategoryMapper.toDto(t).toJson(),
    idOf: (t) => t.id,
  );
}

CrudBloc<TaxCategory, int, void> createTaxCategoryCrudBloc(
  DioClient client,
) {
  return CrudBloc<TaxCategory, int, void>(
    repository: createTaxCategoryRepository(client),
    idOf: (t) => t.id,
  );
}
