import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/organization_currency_rate/currency_rate_manifest.dart';
import 'package:algo_erp_front/features/organization_currency_rate/data/currency_rate_repository.dart';
import 'package:algo_erp_front/features/organization_currency_rate/domain/currency_rate.dart';
import 'package:flutter/widgets.dart';

Repository<CurrencyRate, int> createCurrencyRateRepository(DioClient client) {
  return CurrencyRateRepository(client);
}

CrudBloc<CurrencyRate, int, void> createCurrencyRateCrudBloc(DioClient client) {
  return CrudBloc<CurrencyRate, int, void>(
    repository: createCurrencyRateRepository(client),
    idOf: (rate) => rate.id,
  );
}

CrudBloc<CurrencyRate, int, void> currencyRateCrudBloc(BuildContext context) {
  return CrudBlocScope.of<CurrencyRate, int, void>(
    context,
    currencyRateManifest.id,
    () => createCurrencyRateCrudBloc(getIt<DioClient>()),
  );
}
