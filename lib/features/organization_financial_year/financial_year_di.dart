import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/organization_financial_year/data/financial_year_dto.dart';
import 'package:algo_erp_front/features/organization_financial_year/data/financial_year_mapper.dart';
import 'package:algo_erp_front/features/organization_financial_year/domain/financial_year.dart';
import 'package:algo_erp_front/features/organization_financial_year/financial_year_manifest.dart';

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
