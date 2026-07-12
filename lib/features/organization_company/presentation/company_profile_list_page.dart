import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/organization_company/company_profile_di.dart';
import 'package:algo_erp_front/features/organization_company/company_profile_manifest.dart';
import 'package:algo_erp_front/features/organization_company/domain/company_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CompanyProfileListPage extends StatelessWidget {
  const CompanyProfileListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<CompanyProfile, int, void>>.value(
      value: companyProfileCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<CompanyProfile>(
          manifest: companyProfileManifest,
          idOf: (c) => c.id,
          // Create is company-provision (out of band); open existing only.
          onTap: (c) => context.push('/organization/companies/${c.id}'),
        ),
      ),
    );
  }
}
