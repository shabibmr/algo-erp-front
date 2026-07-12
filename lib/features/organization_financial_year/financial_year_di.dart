import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/organization_financial_year/data/financial_year_dto.dart';
import 'package:algo_erp_front/features/organization_financial_year/data/financial_year_mapper.dart';
import 'package:algo_erp_front/features/organization_financial_year/domain/financial_year.dart';
import 'package:algo_erp_front/features/organization_financial_year/financial_year_manifest.dart';
import 'package:flutter/widgets.dart';

const _financialYearMapper = FinancialYearMapper();

RemoteRepository<FinancialYear, int> createFinancialYearRepository(
  DioClient client,
) {
  return buildRepository<FinancialYear, int>(
    client: client,
    resourcePath: financialYearManifest.resourcePath,
    decode: (json) =>
        _financialYearMapper.toEntity(FinancialYearDto.fromJson(json)),
    encode: (fy) => _financialYearMapper.toDto(fy).toJson(),
    idOf: (fy) => fy.id,
  );
}

CrudBloc<FinancialYear, int, void> createFinancialYearCrudBloc(
  DioClient client,
) {
  return CrudBloc<FinancialYear, int, void>(
    repository: createFinancialYearRepository(client),
    idOf: (fy) => fy.id,
  );
}

/// The one FinancialYear [CrudBloc], shared by the list and form routes via the
/// [CrudBlocScope] in `AppShell`. Both pages must go through this —
/// resolving the bloc any other way gives the form a private instance the
/// list never sees, which is how created rows went missing.
CrudBloc<FinancialYear, int, void> financialYearCrudBloc(BuildContext context) {
  return CrudBlocScope.of<FinancialYear, int, void>(
    context,
    financialYearManifest.id,
    () => createFinancialYearCrudBloc(getIt<DioClient>()),
  );
}
