import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/organization_currency/currency_manifest.dart';
import 'package:algo_erp_front/features/organization_currency/data/currency_dto.dart';
import 'package:algo_erp_front/features/organization_currency/data/currency_mapper.dart';
import 'package:algo_erp_front/features/organization_currency/domain/currency.dart';
import 'package:flutter/widgets.dart';

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

/// The one Currency [CrudBloc], shared by the list and form routes via the
/// [CrudBlocScope] in `AppShell`. Both pages must go through this —
/// resolving the bloc any other way gives the form a private instance the
/// list never sees, which is how created rows went missing.
CrudBloc<Currency, int, void> currencyCrudBloc(BuildContext context) {
  return CrudBlocScope.of<Currency, int, void>(
    context,
    currencyManifest.id,
    () => createCurrencyCrudBloc(getIt<DioClient>()),
  );
}
