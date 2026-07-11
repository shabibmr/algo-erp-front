import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/data/remote_data_source_base.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_brand/brand_manifest.dart';
import 'package:algo_erp_front/features/inventory_brand/data/brand_dto.dart';
import 'package:algo_erp_front/features/inventory_brand/data/brand_mapper.dart';
import 'package:algo_erp_front/features/inventory_brand/domain/brand.dart';

/// Plain factory functions, not `@injectable` — Brand is the EMR slice's
/// only manifest-bound feature so far, and a generic `RepoBinding` DI helper
/// (proposed in `docs/BUILD_TASKS_V2.md`) is explicitly deferred until more
/// than one entity needs the same wiring. Once it exists, these two
/// functions collapse into one call.
const _brandMapper = BrandMapper();

RemoteRepository<Brand, int> createBrandRepository(DioClient client) {
  return RemoteRepository<Brand, int>(
    dataSource: RemoteDataSourceBase(client, brandManifest.resourcePath),
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
