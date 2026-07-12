import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/organization_currency_rate/currency_rate_di.dart';
import 'package:algo_erp_front/features/organization_currency_rate/currency_rate_manifest.dart';
import 'package:algo_erp_front/features/organization_currency_rate/domain/currency_rate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CurrencyRateListPage extends StatelessWidget {
  const CurrencyRateListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<CurrencyRate, int, void>>.value(
      value: currencyRateCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<CurrencyRate>(
          manifest: currencyRateManifest,
          idOf: (r) => r.id,
          onCreate: () => context.push('/organization/rates/new'),
          onTap: (r) => context.push('/organization/rates/${r.id}'),
        ),
      ),
    );
  }
}
