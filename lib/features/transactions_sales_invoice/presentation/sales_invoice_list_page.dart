import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/export/export_button.dart';
import 'package:algo_erp_front/core/export/export_cubit.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/utils/extensions/format_x.dart';
import 'package:algo_erp_front/core/vouchers/voucher_blueprint.dart';
import 'package:algo_erp_front/core/vouchers/voucher_export.dart';
import 'package:algo_erp_front/core/widgets/fields/app_date_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:algo_erp_front/core/widgets/shortcuts/create_new_shortcuts.dart';
import 'package:algo_erp_front/core/widgets/states/empty_state.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/domain/sales_invoice.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/bloc/sales_invoice_list_bloc.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/bloc/sales_invoice_list_event.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/bloc/sales_invoice_list_state.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/sales_invoice_di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Built once per module, not per build (see CLAUDE.md) — the customer picker
// was allocating a fresh repository on every state change.
final DioClient _dio = getIt<DioClient>();
final _invoiceRepo = createSalesInvoiceRepository(_dio);
final _ledgerRepo = createLedgerRepository(_dio);

/// The same five fields every voucher list exports, with the customer as the
/// party column.
final _exportColumns = voucherExportColumns<SalesInvoiceListItem>(
  displayNo: (i) => i.displayNo,
  voucherDate: (i) => i.voucherDate,
  status: (i) => i.status,
  total: (i) => i.total,
  party: (i) => i.billingName,
  partyLabel: 'Customer',
);

class SalesInvoiceListPage extends StatelessWidget {
  const SalesInvoiceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SalesInvoiceListBloc>(
          create: (_) =>
              SalesInvoiceListBloc(repository: _invoiceRepo)
                ..add(const SalesInvoiceListFetchRequested()),
        ),
        BlocProvider<ExportCubit<SalesInvoiceListItem>>(
          create: (_) =>
              ExportCubit<SalesInvoiceListItem>(source: _invoiceRepo.list),
        ),
      ],
      child: BlocListener<SalesInvoiceListBloc, SalesInvoiceListState>(
        // A failed *append* keeps the pages already on screen, so it never
        // reaches the full-page ErrorState — surface it here rather than
        // letting the load-more fail silently.
        listenWhen: (prev, curr) =>
            curr.isSuccess &&
            curr.failure != null &&
            prev.failure != curr.failure,
        listener: (context, state) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.failure!.message)));
        },
        child: const _SalesInvoiceListView(),
      ),
    );
  }
}

class _SalesInvoiceListView extends StatelessWidget {
  const _SalesInvoiceListView();

  static const _bp = VoucherBlueprints.salesInvoice;
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
      child: BlocBuilder<SalesInvoiceListBloc, SalesInvoiceListState>(
        builder: (context, state) {
          final bloc = context.read<SalesInvoiceListBloc>();

          return CreateNewShortcuts(
            module: _bp.rbacModule,
            onCreate: () => context.push('/transactions/sales-invoices/new'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _bp.label,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    ExportButton<SalesInvoiceListItem>(
                      id: 'sales_invoices',
                      label: _bp.label,
                      columns: _exportColumns,
                      query: () => state.query,
                    ),
                    IconButton(
                      tooltip: 'Filters',
                      onPressed: () =>
                          bloc.add(const SalesInvoiceListFilterToggled()),
                      icon: Icon(
                        state.filtersExpanded
                            ? Icons.filter_alt
                            : Icons.filter_alt_outlined,
                      ),
                    ),
                    PermissionGate(
                      module: _bp.rbacModule,
                      action: PermissionAction.create,
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.push('/transactions/sales-invoices/new'),
                        icon: const Icon(Icons.add),
                        label: const Text('New'),
                      ),
                    ),
                  ],
                ),
                if (state.filtersExpanded) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: AppDateField(
                                  label: 'From date',
                                  value: state.startDate,
                                  onChanged: (d) => bloc.add(
                                    SalesInvoiceListStartDateChanged(d),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppDateField(
                                  label: 'To date',
                                  value: state.endDate,
                                  onChanged: (d) => bloc.add(
                                    SalesInvoiceListEndDateChanged(d),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String?>(
                            initialValue: state.statusFilter,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                child: Text('Any status'),
                              ),
                              for (final s in _statuses)
                                DropdownMenuItem(value: s, child: Text(s)),
                            ],
                            onChanged: (v) =>
                                bloc.add(SalesInvoiceListStatusChanged(v)),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'Prefix',
                            value: state.prefix,
                            hintText: 'SI',
                            onChanged: (v) =>
                                bloc.add(SalesInvoiceListPrefixChanged(v)),
                          ),
                          const SizedBox(height: 12),
                          FkLookupField<Ledger>(
                            label: 'Customer',
                            value: state.customer,
                            displayOf: (l) {
                              final code = l.code;
                              return (code == null || code.isEmpty)
                                  ? l.name
                                  : '$code — ${l.name}';
                            },
                            loader: (q) async {
                              final r = await _ledgerRepo.list(
                                PageQuery(search: q),
                              );
                              return r.fold((_) => const [], (p) => p.items);
                            },
                            onSelected: (l) =>
                                bloc.add(SalesInvoiceListCustomerChanged(l)),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'Search',
                            value: state.search,
                            hintText: 'Number or billing name',
                            onChanged: (v) =>
                                bloc.add(SalesInvoiceListSearchChanged(v)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => bloc.add(
                                  const SalesInvoiceListFiltersCleared(),
                                ),
                                child: const Text('Clear'),
                              ),
                              const Spacer(),
                              FilledButton(
                                onPressed: () => bloc.add(
                                  const SalesInvoiceListFiltersApplied(),
                                ),
                                child: const Text('Apply'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Expanded(child: _buildListContent(context, state, bloc)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildListContent(
    BuildContext context,
    SalesInvoiceListState state,
    SalesInvoiceListBloc bloc,
  ) {
    if (state.isLoading) {
      return const LoadingState();
    }
    if (state.isFailure) {
      return ErrorState(
        failure: state.failure ?? const Failure.unknown('Failed to load list'),
        onRetry: () => bloc.add(const SalesInvoiceListFetchRequested()),
      );
    }
    if (state.items.isEmpty) {
      return const EmptyState(message: 'No sales invoices match these filters');
    }

    // One extra slot for the load-more footer (spinner, or the end-of-list
    // count once every page is in).
    final itemCount = state.items.length + 1;

    return RefreshIndicator(
      onRefresh: () async {
        bloc.add(const SalesInvoiceListRefreshed());
      },
      // A NotificationListener reads the scroll position without a
      // ScrollController, which would need a StatefulWidget to dispose. The
      // bloc drops the event when there is no next page or one is in flight,
      // so firing on every scroll near the end is safe.
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final metrics = notification.metrics;
          if (state.hasMore &&
              !state.isLoadingMore &&
              metrics.axis == Axis.vertical &&
              metrics.pixels >= metrics.maxScrollExtent - 240) {
            bloc.add(const SalesInvoiceListLoadMoreRequested());
          }
          return false;
        },
        child: ListView.separated(
          itemCount: itemCount,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            if (i == state.items.length) {
              return _ListFooter(
                isLoadingMore: state.isLoadingMore,
                hasMore: state.hasMore,
                shown: state.items.length,
                total: state.total,
              );
            }
            final row = state.items[i];
            final date = row.voucherDate;
            final subtitle = [
              if (date != null) date.toDayString(),
              if (row.status != null) row.status!,
              if (row.billingName != null) row.billingName!,
            ].join(' · ');
            return ListTile(
              title: Text(row.displayNo.isEmpty ? '#${row.id}' : row.displayNo),
              subtitle: Text(subtitle),
              trailing: row.total == null ? null : Text(row.total!.toMoney()),
              onTap: () =>
                  context.push('/transactions/sales-invoices/${row.id}'),
            );
          },
        ),
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({
    required this.isLoadingMore,
    required this.hasMore,
    required this.shown,
    required this.total,
  });

  final bool isLoadingMore;
  final bool hasMore;
  final int shown;
  final int? total;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    // Still more to fetch, but not fetching yet — leave the slot empty rather
    // than claiming the list has ended.
    if (hasMore) return const SizedBox(height: 24);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          total == null ? '$shown shown' : 'All $total shown',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
