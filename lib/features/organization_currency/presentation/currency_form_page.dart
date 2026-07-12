import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/organization_currency/currency_di.dart';
import 'package:algo_erp_front/features/organization_currency/currency_manifest.dart';
import 'package:algo_erp_front/features/organization_currency/domain/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CurrencyFormPage extends StatelessWidget {
  const CurrencyFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<Currency, int>>(
      create: (_) => createCurrencyRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          // The surface has already persisted through the repository by the
          // time these fire, so the shared list bloc is told to refetch —
          // never CrudItemCreated/Updated/Deleted, which would write again.
          void refreshListAndReturn() {
            currencyCrudBloc(context).add(const CrudRefreshRequested());
            context.go(currencyManifest.resourcePath);
          }

          final surface = MasterFormSurface<Currency, int>(
            manifest: currencyManifest,
            mode: mode,
            idOf: (currency) => currency.id,
            onSaved: (_) => refreshListAndReturn(),
            onDeleted: refreshListAndReturn,
          );
          return AdaptiveLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode == FormMode.create
                      ? 'New ${currencyManifest.label}'
                      : currencyManifest.supportsUpdate
                      ? 'Edit ${currencyManifest.label}'
                      : 'View ${currencyManifest.label}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                if (mode == FormMode.edit)
                  BlocProvider<DetailBloc<Currency, int>>(
                    create: (ctx) => DetailBloc<Currency, int>(
                      repository: ctx.read<Repository<Currency, int>>(),
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
