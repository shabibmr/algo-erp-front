import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_tax_category/data/tax_category_dto.dart';
import 'package:algo_erp_front/features/inventory_tax_category/data/tax_category_mapper.dart';
import 'package:algo_erp_front/features/inventory_tax_category/domain/tax_category.dart';
import 'package:algo_erp_front/features/inventory_tax_category/tax_category_manifest.dart';
import 'package:flutter/widgets.dart';

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

CrudBloc<TaxCategory, int, void> createTaxCategoryCrudBloc(DioClient client) {
  return CrudBloc<TaxCategory, int, void>(
    repository: createTaxCategoryRepository(client),
    idOf: (t) => t.id,
  );
}

/// The one TaxCategory [CrudBloc], shared by the list and form routes via the
/// [CrudBlocScope] in `AppShell`. Both pages must go through this —
/// resolving the bloc any other way gives the form a private instance the
/// list never sees, which is how created rows went missing.
CrudBloc<TaxCategory, int, void> taxCategoryCrudBloc(BuildContext context) {
  return CrudBlocScope.of<TaxCategory, int, void>(
    context,
    taxCategoryManifest.id,
    () => createTaxCategoryCrudBloc(getIt<DioClient>()),
  );
}
