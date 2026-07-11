import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_uom_conversion/data/uom_conversion_dto.dart';
import 'package:algo_erp_front/features/inventory_uom_conversion/data/uom_conversion_mapper.dart';
import 'package:algo_erp_front/features/inventory_uom_conversion/domain/uom_conversion.dart';
import 'package:algo_erp_front/features/inventory_uom_conversion/uom_conversion_manifest.dart';

const _uomConversionMapper = UomConversionMapper();

RemoteRepository<UomConversion, int> createUomConversionRepository(
  DioClient client,
) {
  return buildRepository<UomConversion, int>(
    client: client,
    resourcePath: uomConversionManifest.resourcePath,
    decode: (json) =>
        _uomConversionMapper.toEntity(UomConversionDto.fromJson(json)),
    encode: (u) => _uomConversionMapper.toDto(u).toJson(),
    idOf: (u) => u.id,
  );
}

CrudBloc<UomConversion, int, void> createUomConversionCrudBloc(
  DioClient client,
) {
  return CrudBloc<UomConversion, int, void>(
    repository: createUomConversionRepository(client),
    idOf: (u) => u.id,
  );
}
