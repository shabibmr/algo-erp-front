import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_pricelist/data/price_list_dto.dart';
import 'package:algo_erp_front/features/inventory_pricelist/data/price_list_mapper.dart';
import 'package:algo_erp_front/features/inventory_pricelist/domain/price_list.dart';
import 'package:algo_erp_front/features/inventory_pricelist/price_list_manifest.dart';

const _priceListMapper = PriceListMapper();

RemoteRepository<PriceList, int> createPriceListRepository(
  DioClient client,
) {
  return buildRepository<PriceList, int>(
    client: client,
    resourcePath: priceListManifest.resourcePath,
    decode: (json) => _priceListMapper.toEntity(PriceListDto.fromJson(json)),
    encode: (p) => _priceListMapper.toDto(p).toJson(),
    idOf: (p) => p.id,
  );
}

CrudBloc<PriceList, int, void> createPriceListCrudBloc(DioClient client) {
  return CrudBloc<PriceList, int, void>(
    repository: createPriceListRepository(client),
    idOf: (p) => p.id,
  );
}
