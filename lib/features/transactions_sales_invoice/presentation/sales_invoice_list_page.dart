import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/utils/extensions/format_x.dart';
import 'package:algo_erp_front/core/vouchers/voucher_blueprint.dart';
import 'package:algo_erp_front/core/widgets/fields/app_date_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:algo_erp_front/core/widgets/states/empty_state.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/domain/sales_invoice.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/sales_invoice_di.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SalesInvoiceListPage extends StatefulWidget {
  const SalesInvoiceListPage({super.key});

  @override
  State<SalesInvoiceListPage> createState() => _SalesInvoiceListPageState();
}

class _SalesInvoiceListPageState extends State<SalesInvoiceListPage> {
  static const _bp = VoucherBlueprints.salesInvoice;
  static const _statuses = [
    'Draft',
    'Approved',
    'Posted',
    'Cancelled',
    'Rejected',
  ];

  late final _repo = createSalesInvoiceRepository(getIt<DioClient>());
  late final _ledgerRepo = createLedgerRepository(getIt<DioClient>());
  Future<Paginated<SalesInvoiceListItem>>? _future;

  DateTime? _startDate;
  DateTime? _endDate;
  String? _status;
  String _prefix = '';
  Ledger? _customer;
  String _search = '';
  bool _filtersExpanded = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  String? _ymd(DateTime? d) {
    if (d == null) return null;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  PageQuery get _query => PageQuery(
    search: _search.isEmpty ? null : _search,
    filters: {
      if (_ymd(_startDate) != null) 'start_date': _ymd(_startDate),
      if (_ymd(_endDate) != null) 'end_date': _ymd(_endDate),
      if (_status != null) 'status': _status,
      if (_prefix.trim().isNotEmpty) 'prefix': _prefix.trim(),
      if (_customer != null) 'ledger_id': _customer!.id,
    },
  );

  void _reload() {
    setState(() => _future = _load());
  }

  Future<Paginated<SalesInvoiceListItem>> _load() async {
    final result = await _repo.list(_query);
    return result.fold(
      (failure) => throw Exception(failure.toString()),
      (page) => page,
    );
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _status = null;
      _prefix = '';
      _customer = null;
      _search = '';
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
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
              IconButton(
                tooltip: 'Filters',
                onPressed: () =>
                    setState(() => _filtersExpanded = !_filtersExpanded),
                icon: Icon(
                  _filtersExpanded
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
          if (_filtersExpanded) ...[
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
                            value: _startDate,
                            onChanged: (d) => setState(() => _startDate = d),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppDateField(
                            label: 'To date',
                            value: _endDate,
                            onChanged: (d) => setState(() => _endDate = d),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: [
                        const DropdownMenuItem<String?>(
                          child: Text('Any status'),
                        ),
                        for (final s in _statuses)
                          DropdownMenuItem(value: s, child: Text(s)),
                      ],
                      onChanged: (v) => setState(() => _status = v),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Prefix',
                      initialValue: _prefix,
                      hintText: 'SI',
                      onChanged: (v) => _prefix = v,
                    ),
                    const SizedBox(height: 12),
                    FkLookupField<Ledger>(
                      label: 'Customer',
                      value: _customer,
                      displayOf: (l) {
                        final code = l.code;
                        return (code == null || code.isEmpty)
                            ? l.name
                            : '$code — ${l.name}';
                      },
                      loader: (q) async {
                        final r = await _ledgerRepo.list(PageQuery(search: q));
                        return r.fold((_) => const [], (p) => p.items);
                      },
                      onSelected: (l) => setState(() => _customer = l),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Search',
                      initialValue: _search,
                      hintText: 'Number or billing name',
                      onChanged: (v) => _search = v,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _reload,
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
          Expanded(
            child: FutureBuilder<Paginated<SalesInvoiceListItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingState();
                }
                if (snapshot.hasError) {
                  final err = snapshot.error;
                  final failure = err is Failure
                      ? err
                      : Failure.unknown(err.toString());
                  return ErrorState(failure: failure, onRetry: _reload);
                }
                final page = snapshot.data;
                if (page == null || page.items.isEmpty) {
                  return const EmptyState(
                    message: 'No sales invoices match these filters',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    itemCount: page.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final row = page.items[i];
                      final date = row.voucherDate;
                      final subtitle = [
                        if (date != null) date.toDayString(),
                        if (row.status != null) row.status!,
                        if (row.billingName != null) row.billingName!,
                      ].join(' · ');
                      return ListTile(
                        title: Text(
                          row.displayNo.isEmpty ? '#${row.id}' : row.displayNo,
                        ),
                        subtitle: Text(subtitle),
                        trailing: row.total == null
                            ? null
                            : Text(row.total!.toMoney()),
                        onTap: () => context.push(
                          '/transactions/sales-invoices/${row.id}',
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
