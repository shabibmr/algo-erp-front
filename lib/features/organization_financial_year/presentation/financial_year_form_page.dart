import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/organization_financial_year/domain/financial_year.dart';
import 'package:algo_erp_front/features/organization_financial_year/financial_year_di.dart';
import 'package:algo_erp_front/features/organization_financial_year/financial_year_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class FinancialYearFormPage extends StatelessWidget {
  const FinancialYearFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<FinancialYear, int>>(
      create: (_) => createFinancialYearRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          // The surface has already persisted through the repository by the
          // time these fire, so the shared list bloc is told to refetch —
          // never CrudItemCreated/Updated/Deleted, which would write again.
          void refreshListAndReturn() {
            financialYearCrudBloc(context).add(const CrudRefreshRequested());
            context.go(financialYearManifest.resourcePath);
          }

          final surface = MasterFormSurface<FinancialYear, int>(
            manifest: financialYearManifest,
            mode: mode,
            idOf: (fy) => fy.id,
            onSaved: (_) => refreshListAndReturn(),
            onDeleted: refreshListAndReturn,
          );
          return AdaptiveLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode == FormMode.create
                      ? 'New ${financialYearManifest.label}'
                      : financialYearManifest.supportsUpdate
                      ? 'Edit ${financialYearManifest.label}'
                      : 'View ${financialYearManifest.label}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                if (mode == FormMode.edit)
                  BlocProvider<DetailBloc<FinancialYear, int>>(
                    create: (ctx) => DetailBloc<FinancialYear, int>(
                      repository: ctx.read<Repository<FinancialYear, int>>(),
                      id: entityId!,
                    )..add(const DetailLoadRequested()),
                    child: surface,
                  )
                else
                  surface,
              ],
            ),
          );
        },
      ),
    );
  }
}
