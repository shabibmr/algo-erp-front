import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_sku/data/sku_master_dto.dart';
import 'package:algo_erp_front/features/inventory_sku/data/sku_master_mapper.dart';
import 'package:algo_erp_front/features/inventory_sku/domain/sku_master.dart';
import 'package:algo_erp_front/features/inventory_sku/sku_master_manifest.dart';

const _skuMasterMapper = SkuMasterMapper();

RemoteRepository<SkuMaster, int> createSkuMasterRepository(DioClient client) {
  return buildRepository<SkuMaster, int>(
    client: client,
    resourcePath: skuMasterManifest.resourcePath,
    decode: (json) => _skuMasterMapper.toEntity(SkuMasterDto.fromJson(json)),
    encode: (sku) => _skuMasterMapper.toDto(sku).toJson(),
    idOf: (sku) => sku.id,
  );
}

CrudBloc<SkuMaster, int, void> createSkuMasterCrudBloc(DioClient client) {
  return CrudBloc<SkuMaster, int, void>(
    repository: createSkuMasterRepository(client),
    idOf: (sku) => sku.id,
  );
}
