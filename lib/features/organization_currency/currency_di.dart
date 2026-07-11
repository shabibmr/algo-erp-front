import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/organization_currency/currency_manifest.dart';
import 'package:algo_erp_front/features/organization_currency/data/currency_dto.dart';
import 'package:algo_erp_front/features/organization_currency/data/currency_mapper.dart';
import 'package:algo_erp_front/features/organization_currency/domain/currency.dart';

const _currencyMapper = CurrencyMapper();

RemoteRepository<Currency, int> createCurrencyRepository(DioClient client) {
  return buildRepository<Currency, int>(
    client: client,
    resourcePath: currencyManifest.resourcePath,
    decode: (json) => _currencyMapper.toEntity(CurrencyDto.fromJson(json)),
    encode: (currency) => _currencyMapper.toDto(currency).toJson(),
    idOf: (currency) => currency.id,
  );
}

CrudBloc<Currency, int, void> createCurrencyCrudBloc(DioClient client) {
  return CrudBloc<Currency, int, void>(
    repository: createCurrencyRepository(client),
    idOf: (currency) => currency.id,
  );
}
