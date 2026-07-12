import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/accounts_account_group/account_group_di.dart';
import 'package:algo_erp_front/features/accounts_account_group/account_group_manifest.dart';
import 'package:algo_erp_front/features/accounts_account_group/domain/account_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AccountGroupListPage extends StatelessWidget {
  const AccountGroupListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // `.value`, not `create:` — the bloc is owned by the CrudBlocScope
    // in AppShell so the form route shares it. See accountGroupCrudBloc.
    return BlocProvider<CrudBloc<AccountGroup, int, void>>.value(
      value: accountGroupCrudBloc(context),
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              accountGroupManifest.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MasterListSurface<AccountGroup>(
                manifest: accountGroupManifest,
                idOf: (g) => g.id,
                onCreate: () => context.push('/accounts/groups/new'),
                onTap: (g) => context.push('/accounts/groups/${g.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
