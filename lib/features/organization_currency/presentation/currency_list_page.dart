import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/organization_currency/currency_di.dart';
import 'package:algo_erp_front/features/organization_currency/currency_manifest.dart';
import 'package:algo_erp_front/features/organization_currency/domain/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CurrencyListPage extends StatelessWidget {
  const CurrencyListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<Currency, int, void>>(
      create: (_) => createCurrencyCrudBloc(getIt<DioClient>())
        ..add(const CrudLoadRequested()),
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currencyManifest.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MasterListSurface<Currency>(
                manifest: currencyManifest,
                idOf: (currency) => currency.id,
                onCreate: () => context.push('/organization/currencies/new'),
                onTap: (currency) =>
                    context.push('/organization/currencies/${currency.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
