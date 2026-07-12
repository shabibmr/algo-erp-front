import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/organization_company/company_profile_di.dart';
import 'package:algo_erp_front/features/organization_company/company_profile_manifest.dart';
import 'package:algo_erp_front/features/organization_company/domain/company_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CompanyProfileFormPage extends StatelessWidget {
  const CompanyProfileFormPage({required this.entityId, super.key});

  final int entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<CompanyProfile, int>>(
      create: (_) => createCompanyProfileRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          void refreshListAndReturn() {
            companyProfileCrudBloc(context).add(const CrudRefreshRequested());
            context.go(companyProfileManifest.resourcePath);
          }

          final surface = MasterFormSurface<CompanyProfile, int>(
            manifest: companyProfileManifest,
            mode: FormMode.edit,
            idOf: (c) => c.id,
            onSaved: (_) => refreshListAndReturn(),
            onDeleted: refreshListAndReturn,
            onCancel: () => context.go(companyProfileManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: BlocProvider<DetailBloc<CompanyProfile, int>>(
              create: (ctx) => DetailBloc<CompanyProfile, int>(
                repository: ctx.read<Repository<CompanyProfile, int>>(),
                id: entityId,
              )..add(const DetailLoadRequested()),
              child: surface,
            ),
          );
        },
      ),
    );
  }
}
