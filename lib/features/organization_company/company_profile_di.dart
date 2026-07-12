import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/organization_company/company_profile_manifest.dart';
import 'package:algo_erp_front/features/organization_company/data/company_profile_repository.dart';
import 'package:algo_erp_front/features/organization_company/domain/company_profile.dart';
import 'package:flutter/widgets.dart';

Repository<CompanyProfile, int> createCompanyProfileRepository(
  DioClient client,
) {
  return CompanyProfileRepository(client);
}

CrudBloc<CompanyProfile, int, void> createCompanyProfileCrudBloc(
  DioClient client,
) {
  return CrudBloc<CompanyProfile, int, void>(
    repository: createCompanyProfileRepository(client),
    idOf: (c) => c.id,
  );
}

CrudBloc<CompanyProfile, int, void> companyProfileCrudBloc(
  BuildContext context,
) {
  return CrudBlocScope.of<CompanyProfile, int, void>(
    context,
    companyProfileManifest.id,
    () => createCompanyProfileCrudBloc(getIt<DioClient>()),
  );
}
