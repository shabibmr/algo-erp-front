import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/organization_currency_rate/currency_rate_di.dart';
import 'package:algo_erp_front/features/organization_currency_rate/currency_rate_manifest.dart';
import 'package:algo_erp_front/features/organization_currency_rate/domain/currency_rate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CurrencyRateFormPage extends StatelessWidget {
  const CurrencyRateFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<CurrencyRate, int>>(
      create: (_) => createCurrencyRateRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          void refreshListAndReturn() {
            currencyRateCrudBloc(context).add(const CrudRefreshRequested());
            context.go(currencyRateManifest.resourcePath);
          }

          final surface = MasterFormSurface<CurrencyRate, int>(
            manifest: currencyRateManifest,
            mode: mode,
            idOf: (r) => r.id,
            onSaved: (_) => refreshListAndReturn(),
            onDeleted: refreshListAndReturn,
            onCancel: () => context.go(currencyRateManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: mode == FormMode.edit
                ? BlocProvider<DetailBloc<CurrencyRate, int>>(
                    create: (ctx) => DetailBloc<CurrencyRate, int>(
                      repository: ctx.read<Repository<CurrencyRate, int>>(),
                      id: entityId!,
                    )..add(const DetailLoadRequested()),
                    child: surface,
                  )
                : surface,
          );
        },
      ),
    );
  }
}
