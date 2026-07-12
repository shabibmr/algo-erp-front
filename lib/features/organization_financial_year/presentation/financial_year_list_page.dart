import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/organization_financial_year/domain/financial_year.dart';
import 'package:algo_erp_front/features/organization_financial_year/financial_year_di.dart';
import 'package:algo_erp_front/features/organization_financial_year/financial_year_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class FinancialYearListPage extends StatelessWidget {
  const FinancialYearListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // `.value`, not `create:` — the bloc is owned by the CrudBlocScope
    // in AppShell so the form route shares it. See financialYearCrudBloc.
    return BlocProvider<CrudBloc<FinancialYear, int, void>>.value(
      value: financialYearCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<FinancialYear>(
          manifest: financialYearManifest,
          idOf: (fy) => fy.id,
          onCreate: () => context.push('/organization/fy/new'),
          onTap: (fy) => context.push('/organization/fy/${fy.id}'),
        ),
      ),
    );
  }
}
