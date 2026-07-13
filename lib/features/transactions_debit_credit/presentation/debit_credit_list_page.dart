import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/utils/extensions/format_x.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_kind.dart';
import 'package:algo_erp_front/core/widgets/fields/app_date_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/states/empty_state.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/transactions_debit_credit/bloc/debit_credit_list_bloc.dart';
import 'package:algo_erp_front/features/transactions_debit_credit/bloc/debit_credit_list_event.dart';
import 'package:algo_erp_front/features/transactions_debit_credit/bloc/debit_credit_list_state.dart';
import 'package:algo_erp_front/features/transactions_debit_credit/debit_credit_di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Paginated list for Journal / Contra powered by flutter_bloc.
class DebitCreditListPage extends StatelessWidget {
  const DebitCreditListPage({required this.kind, super.key});

  final DebitCreditVoucherKind kind;

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<DebitCreditListBloc>(
      create: (_) => DebitCreditListBloc(
        repository: createDebitCreditRepository(dio, kind),
        kind: kind,
      )..add(const DebitCreditListFetchRequested()),
      child: const _DebitCreditListView(),
    );
  }
}

class _DebitCreditListView extends StatelessWidget {
  const _DebitCreditListView();

  static const _statuses = [
    'Draft',
    'Approved',
    'Posted',
    'Cancelled',
    'Rejected',
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: BlocBuilder<DebitCreditListBloc, DebitCreditListState>(
        builder: (context, state) {
          final bloc = context.read<DebitCreditListBloc>();
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
                    onPressed: () =>
                        bloc.add(const DebitCreditListFilterToggled()),
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
                            bloc.add(DebitCreditListStartDateChanged(d)),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: AppDateField(
                        label: 'To',
                        value: state.endDate,
                        onChanged: (d) =>
                            bloc.add(DebitCreditListEndDateChanged(d)),
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
                        onChanged: (v) =>
                            bloc.add(DebitCreditListStatusChanged(v)),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: AppTextField(
                        label: 'Prefix',
                        value: state.prefix,
                        onChanged: (v) =>
                            bloc.add(DebitCreditListPrefixChanged(v)),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: AppTextField(
                        label: 'Search',
                        value: state.search,
                        onChanged: (v) =>
                            bloc.add(DebitCreditListSearchChanged(v)),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          bloc.add(const DebitCreditListFiltersCleared()),
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
    DebitCreditListState state,
    DebitCreditListBloc bloc,
  ) {
    final bp = state.kind.blueprint;

    if (state.isLoading) {
      return const LoadingState();
    }
    if (state.isFailure) {
      return ErrorState(
        failure: state.failure ?? const Failure.unknown('Failed to load list'),
        onRetry: () => bloc.add(const DebitCreditListFetchRequested()),
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
      onRefresh: () async => bloc.add(const DebitCreditListRefreshed()),
      child: ListView.separated(
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final row = state.items[i];
          return ListTile(
            title: Text(row.displayNo),
            subtitle: Text(
              [
                if (row.status != null) row.status!,
                if (row.voucherDate != null) row.voucherDate!.toDayString(),
                if (row.narration != null && row.narration!.isNotEmpty)
                  row.narration!,
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
