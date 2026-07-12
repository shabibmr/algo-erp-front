import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LedgerListPage extends StatelessWidget {
  const LedgerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<Ledger, int, void>>(
      create: (_) => createLedgerCrudBloc(getIt<DioClient>())
        ..add(const CrudLoadRequested()),
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ledgerManifest.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MasterListSurface<Ledger>(
                manifest: ledgerManifest,
                idOf: (l) => l.id,
                onCreate: () => context.push('/accounts/ledgers/new'),
                onTap: (l) => context.push('/accounts/ledgers/${l.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
