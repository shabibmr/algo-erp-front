import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/utils/extensions/format_x.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_kind.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_models.dart';
import 'package:algo_erp_front/core/widgets/fields/app_date_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:algo_erp_front/core/widgets/states/empty_state.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/transactions_item_qty/item_qty_di.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Paginated list for any [ItemQtyVoucherKind].
class ItemQtyListPage extends StatefulWidget {
  const ItemQtyListPage({required this.kind, super.key});

  final ItemQtyVoucherKind kind;

  @override
  State<ItemQtyListPage> createState() => _ItemQtyListPageState();
}

class _ItemQtyListPageState extends State<ItemQtyListPage> {
  static const _statuses = [
    'Draft',
    'Approved',
    'Posted',
    'Cancelled',
    'Rejected',
  ];

  late final _repo = createItemQtyRepository(getIt<DioClient>(), widget.kind);
  late final _ledgerRepo = createLedgerRepository(getIt<DioClient>());
  Future<Paginated<ItemQtyListItem>>? _future;

  DateTime? _startDate;
  DateTime? _endDate;
  String? _status;
  String _prefix = '';
  Ledger? _party;
  String _search = '';
  bool _filtersExpanded = false;

  ItemQtyVoucherKind get kind => widget.kind;

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
      if (_party != null) 'ledger_id': _party!.id,
    },
  );

  void _reload() {
    setState(() => _future = _load());
  }

  Future<Paginated<ItemQtyListItem>> _load() async {
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
      _party = null;
      _search = '';
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final bp = kind.blueprint;
    return AdaptiveLayout(
      child: Column(
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
                    setState(() => _filtersExpanded = !_filtersExpanded),
                icon: Icon(
                  _filtersExpanded
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined,
                ),
              ),
              PermissionGate(
                module: bp.rbacModule,
                action: PermissionAction.create,
                child: FilledButton.icon(
                  onPressed: () => context.go(kind.newRoute),
                  icon: const Icon(Icons.add),
                  label: const Text('New'),
                ),
              ),
            ],
          ),
          if (_filtersExpanded) ...[
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
                    value: _startDate,
                    onChanged: (d) {
                      setState(() => _startDate = d);
                      _reload();
                    },
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: AppDateField(
                    label: 'To',
                    value: _endDate,
                    onChanged: (d) {
                      setState(() => _endDate = d);
                      _reload();
                    },
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: [
                      const DropdownMenuItem(child: Text('Any')),
                      for (final s in _statuses)
                        DropdownMenuItem(value: s, child: Text(s)),
                    ],
                    onChanged: (v) {
                      setState(() => _status = v);
                      _reload();
                    },
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: AppTextField(
                    label: 'Prefix',
                    initialValue: _prefix,
                    onChanged: (v) {
                      _prefix = v;
                      _reload();
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: FkLookupField<Ledger>(
                    label: kind.partyLabel,
                    value: _party,
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
                    onSelected: (l) {
                      setState(() => _party = l);
                      _reload();
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: AppTextField(
                    label: 'Search',
                    initialValue: _search,
                    onChanged: (v) {
                      _search = v;
                      _reload();
                    },
                  ),
                ),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<Paginated<ItemQtyListItem>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const LoadingState();
                }
                if (snap.hasError) {
                  final err = snap.error;
                  return ErrorState(
                    failure: err is Failure
                        ? err
                        : Failure.unknown(err.toString()),
                    onRetry: _reload,
                  );
                }
                final page = snap.data!;
                if (page.items.isEmpty) {
                  return EmptyState(
                    message: 'No ${bp.label.toLowerCase()}s match filters',
                    actionLabel: 'New',
                    onAction: () => context.go(kind.newRoute),
                  );
                }
                return ListView.separated(
                  itemCount: page.items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final row = page.items[i];
                    return ListTile(
                      title: Text(row.displayNo),
                      subtitle: Text(
                        [
                          if (row.billingName != null) row.billingName!,
                          if (row.status != null) row.status!,
                          if (row.voucherDate != null)
                            row.voucherDate!.toDayString(),
                        ].join(' · '),
                      ),
                      trailing: row.total == null
                          ? null
                          : Text(row.total!.toString()),
                      onTap: () => context.go(kind.detailRoute(row.id)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
