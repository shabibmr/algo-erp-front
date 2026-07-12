import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
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
    // `.value`, not `create:` — the bloc is owned by the CrudBlocScope
    // in AppShell so the form route shares it. See ledgerCrudBloc.
    return BlocProvider<CrudBloc<Ledger, int, void>>.value(
      value: ledgerCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<Ledger>(
          manifest: ledgerManifest,
          idOf: (l) => l.id,
          onCreate: () => context.push('/accounts/ledgers/new'),
          onTap: (l) => context.push('/accounts/ledgers/${l.id}'),
        ),
      ),
    );
  }
}
