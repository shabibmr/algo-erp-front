import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/utils/extensions/format_x.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_kind.dart';
import 'package:algo_erp_front/core/widgets/fields/app_date_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:algo_erp_front/core/widgets/states/empty_state.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/transactions_item_qty/bloc/item_qty_list_bloc.dart';
import 'package:algo_erp_front/features/transactions_item_qty/bloc/item_qty_list_event.dart';
import 'package:algo_erp_front/features/transactions_item_qty/bloc/item_qty_list_state.dart';
import 'package:algo_erp_front/features/transactions_item_qty/item_qty_di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Paginated list for any [ItemQtyVoucherKind] powered by flutter_bloc.
class ItemQtyListPage extends StatelessWidget {
  const ItemQtyListPage({required this.kind, super.key});

  final ItemQtyVoucherKind kind;

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<ItemQtyListBloc>(
      create: (_) => ItemQtyListBloc(
        repository: createItemQtyRepository(dio, kind),
        kind: kind,
      )..add(const ItemQtyListFetchRequested()),
      child: const _ItemQtyListView(),
    );
  }
}

class _ItemQtyListView extends StatelessWidget {
  const _ItemQtyListView();

  static const _statuses = [
    'Draft',
    'Approved',
    'Posted',
    'Cancelled',
    'Rejected',
  ];

  @override
  Widget build(BuildContext context) {
    final ledgerRepo = createLedgerRepository(getIt<DioClient>());

    return AdaptiveLayout(
      child: BlocBuilder<ItemQtyListBloc, ItemQtyListState>(
        builder: (context, state) {
          final bloc = context.read<ItemQtyListBloc>();
          final bp = state.kind.blueprint;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      bp.label,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Filters',
                    onPressed: () => bloc.add(const ItemQtyListFilterToggled()),
                    icon: Icon(
                      state.filtersExpanded
                          ? Icons.filter_alt
                          : Icons.filter_alt_outlined,
                    ),
                  ),
                  PermissionGate(
                    module: bp.rbacModule,
                    action: PermissionAction.create,
                    child: FilledButton.icon(
                      onPressed: () => context.go(state.kind.newRoute),
                      icon: const Icon(Icons.add),
                      label: const Text('New'),
                    ),
                  ),
                ],
              ),
              if (state.filtersExpanded) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    SizedBox(
                      width: 160,
                      child: AppDateField(
                        label: 'From',
                        value: state.startDate,
                        onChanged: (d) =>
                            bloc.add(ItemQtyListStartDateChanged(d)),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: AppDateField(
                        label: 'To',
                        value: state.endDate,
                        onChanged: (d) =>
                            bloc.add(ItemQtyListEndDateChanged(d)),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<String?>(
                        initialValue: state.selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: [
                          const DropdownMenuItem(child: Text('Any')),
                          for (final s in _statuses)
                            DropdownMenuItem(value: s, child: Text(s)),
                        ],
                        onChanged: (v) => bloc.add(ItemQtyListStatusChanged(v)),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: AppTextField(
                        label: 'Prefix',
                        value: state.prefix,
                        onChanged: (v) => bloc.add(ItemQtyListPrefixChanged(v)),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: FkLookupField<Ledger>(
                        label: state.kind.partyLabel,
                        value: state.party,
                        displayOf: (l) {
                          final code = l.code;
                          return (code == null || code.isEmpty)
                              ? l.name
                              : '$code — ${l.name}';
                        },
                        loader: (q) async {
                          final r = await ledgerRepo.list(PageQuery(search: q));
                          return r.fold((_) => const [], (p) => p.items);
                        },
                        onSelected: (l) => bloc.add(ItemQtyListPartyChanged(l)),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: AppTextField(
                        label: 'Search',
                        value: state.search,
                        onChanged: (v) => bloc.add(ItemQtyListSearchChanged(v)),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          bloc.add(const ItemQtyListFiltersCleared()),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Expanded(child: _buildListContent(context, state, bloc)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListContent(
    BuildContext context,
    ItemQtyListState state,
    ItemQtyListBloc bloc,
  ) {
    final bp = state.kind.blueprint;

    if (state.isLoading) {
      return const LoadingState();
    }
    if (state.isFailure) {
      return ErrorState(
        failure: state.failure ?? const Failure.unknown('Failed to load list'),
        onRetry: () => bloc.add(const ItemQtyListFetchRequested()),
      );
    }
    if (state.items.isEmpty) {
      return EmptyState(
        message: 'No ${bp.label.toLowerCase()}s match filters',
        actionLabel: 'New',
        onAction: () => context.go(state.kind.newRoute),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => bloc.add(const ItemQtyListRefreshed()),
      child: ListView.separated(
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final row = state.items[i];
          return ListTile(
            title: Text(row.displayNo),
            subtitle: Text(
              [
                if (row.billingName != null) row.billingName!,
                if (row.status != null) row.status!,
                if (row.voucherDate != null) row.voucherDate!.toDayString(),
              ].join(' · '),
            ),
            trailing: row.total == null ? null : Text(row.total!.toString()),
            onTap: () => context.go(state.kind.detailRoute(row.id)),
          );
        },
      ),
    );
  }
}
