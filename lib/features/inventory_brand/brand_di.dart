import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_brand/brand_manifest.dart';
import 'package:algo_erp_front/features/inventory_brand/data/brand_dto.dart';
import 'package:algo_erp_front/features/inventory_brand/data/brand_mapper.dart';
import 'package:algo_erp_front/features/inventory_brand/domain/brand.dart';
import 'package:flutter/widgets.dart';

/// Plain factory functions, not `@injectable` — see `buildRepository`'s doc
/// comment for why a full DI registry still isn't warranted.
const _brandMapper = BrandMapper();

RemoteRepository<Brand, int> createBrandRepository(DioClient client) {
  return buildRepository<Brand, int>(
    client: client,
    resourcePath: brandManifest.resourcePath,
    decode: (json) => _brandMapper.toEntity(BrandDto.fromJson(json)),
    encode: (brand) => _brandMapper.toDto(brand).toJson(),
    idOf: (brand) => brand.id,
  );
}

CrudBloc<Brand, int, void> createBrandCrudBloc(DioClient client) {
  return CrudBloc<Brand, int, void>(
    repository: createBrandRepository(client),
    idOf: (brand) => brand.id,
  );
}

/// The one Brand [CrudBloc], shared by the list and form routes via the
/// [CrudBlocScope] in `AppShell`. Both pages must go through this — resolving
/// the bloc any other way gives the form a private instance that the list
/// never sees, which is precisely how created rows went missing.
CrudBloc<Brand, int, void> brandCrudBloc(BuildContext context) {
  return CrudBlocScope.of<Brand, int, void>(
    context,
    brandManifest.id,
    () => createBrandCrudBloc(getIt<DioClient>()),
  );
}
