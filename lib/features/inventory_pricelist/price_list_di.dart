import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_pricelist/data/price_list_dto.dart';
import 'package:algo_erp_front/features/inventory_pricelist/data/price_list_mapper.dart';
import 'package:algo_erp_front/features/inventory_pricelist/domain/price_list.dart';
import 'package:algo_erp_front/features/inventory_pricelist/price_list_manifest.dart';
import 'package:flutter/widgets.dart';

const _priceListMapper = PriceListMapper();

RemoteRepository<PriceList, int> createPriceListRepository(DioClient client) {
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

/// The one PriceList [CrudBloc], shared by the list and form routes via the
/// [CrudBlocScope] in `AppShell`. Both pages must go through this —
/// resolving the bloc any other way gives the form a private instance the
/// list never sees, which is how created rows went missing.
CrudBloc<PriceList, int, void> priceListCrudBloc(BuildContext context) {
  return CrudBlocScope.of<PriceList, int, void>(
    context,
    priceListManifest.id,
    () => createPriceListCrudBloc(getIt<DioClient>()),
  );
}
