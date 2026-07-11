import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_uom/data/uom_dto.dart';
import 'package:algo_erp_front/features/inventory_uom/data/uom_mapper.dart';
import 'package:algo_erp_front/features/inventory_uom/domain/uom.dart';
import 'package:algo_erp_front/features/inventory_uom/uom_manifest.dart';

const _uomMapper = UomMapper();

RemoteRepository<Uom, int> createUomRepository(DioClient client) {
  return buildRepository<Uom, int>(
    client: client,
    resourcePath: uomManifest.resourcePath,
    decode: (json) => _uomMapper.toEntity(UomDto.fromJson(json)),
    encode: (uom) => _uomMapper.toDto(uom).toJson(),
    idOf: (uom) => uom.id,
  );
}

CrudBloc<Uom, int, void> createUomCrudBloc(DioClient client) {
  return CrudBloc<Uom, int, void>(
    repository: createUomRepository(client),
    idOf: (uom) => uom.id,
  );
}
