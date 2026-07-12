import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/utils/extensions/format_x.dart';
import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_kind.dart';
import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_models.dart';
import 'package:algo_erp_front/core/widgets/chips/status_chip.dart';
import 'package:algo_erp_front/core/widgets/dialogs/confirm_dialog.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/inventory_godown/godown_di.dart';
import 'package:algo_erp_front/features/inventory_item/inventory_item_di.dart';
import 'package:algo_erp_front/features/transactions_stock/stock_voucher_di.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StockVoucherDetailPage extends StatefulWidget {
  const StockVoucherDetailPage({
    required this.kind,
    required this.id,
    super.key,
  });

  final StockVoucherKind kind;
  final int id;

  @override
  State<StockVoucherDetailPage> createState() => _StockVoucherDetailPageState();
}

class _StockVoucherDetailPageState extends State<StockVoucherDetailPage> {
  late final _repo = createStockVoucherRepository(
    getIt<DioClient>(),
    widget.kind,
  );
  late final _itemRepo = createInventoryItemRepository(getIt<DioClient>());
  late final _godownRepo = createGodownRepository(getIt<DioClient>());
  Future<StockVoucherDetail>? _future;
  bool _busy = false;

  StockVoucherKind get kind => widget.kind;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() => _future = _load());
  }

  Future<StockVoucherDetail> _load() async {
    final result = await _repo.getById(
      widget.id,
      resolveItemLabel: (itemId) async {
        final r = await _itemRepo.getById(itemId);
        return r.fold(
          (_) => null,
          (item) =>
              item.code.isEmpty ? item.name : '${item.code} — ${item.name}',
        );
      },
      resolveGodownLabel: (godownId) async {
        final r = await _godownRepo.getById(godownId);
        return r.fold((_) => null, (g) => g.name);
      },
    );
    return result.fold((f) => throw Exception(f.toString()), (d) => d);
  }

  String _messageOf(Failure f) => switch (f) {
    NetworkFailure(:final message) => message,
    TimeoutFailure(:final message) => message,
    UnauthorizedFailure(:final message) => message,
    ForbiddenFailure(:final message) => message,
    ValidationFailure(:final message) => message,
    NotFoundFailure(:final message) => message,
    ConflictFailure(:final message) => message,
    ServerFailure(:final message) => message,
    CacheFailure(:final message) => message,
    UnknownFailure(:final message) => message,
  };

  EntityStatus _entityStatus(String status) => switch (status) {
    'Draft' => EntityStatus.draft,
    'Approved' => EntityStatus.approved,
    'Posted' => EntityStatus.posted,
    'Cancelled' => EntityStatus.cancelled,
    'Rejected' => EntityStatus.rejected,
    _ => EntityStatus.posted,
  };

  Future<void> _cancel(StockVoucherDetail doc) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Cancel ${kind.blueprint.label}?',
      message: 'Cancel ${doc.displayNo}?',
      confirmLabel: 'Cancel voucher',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final result = await _repo.cancel(doc.id);
    if (!mounted) return;
    result.fold(
      (f) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_messageOf(f))));
      },
      (_) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cancelled')));
        _reload();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bp = kind.blueprint;
    return AdaptiveLayout(
      child: FutureBuilder<StockVoucherDetail>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingState();
          }
          if (snap.hasError) {
            final err = snap.error;
            return ErrorState(
              failure: err is Failure ? err : Failure.unknown(err.toString()),
              onRetry: _reload,
            );
          }
          final doc = snap.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.go(kind.listRoute),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      doc.displayNo,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  StatusChip(
                    status: _entityStatus(doc.status),
                    label: doc.status,
                  ),
                  if (doc.canCancel && doc.status != 'Cancelled')
                    PermissionGate(
                      module: 'Transactions',
                      action: PermissionAction.update,
                      child: TextButton(
                        onPressed: _busy ? null : () => _cancel(doc),
                        child: const Text('Cancel'),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(bp.label, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  if (doc.voucherDate != null)
                    _kv('Date', doc.voucherDate!.toDayString()),
                  if (doc.fromGodownLabel != null)
                    _kv('From', doc.fromGodownLabel!),
                  if (doc.toGodownLabel != null) _kv('To', doc.toGodownLabel!),
                  if (doc.godownLabel != null) _kv('Godown', doc.godownLabel!),
                  if (doc.billingName != null) _kv('Billing', doc.billingName!),
                  if (doc.requirementVoucherNo != null)
                    _kv('Requirement', doc.requirementVoucherNo!),
                  if (doc.total != null) _kv('Total', doc.total.toString()),
                ],
              ),
              if (doc.narration != null && doc.narration!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(doc.narration!),
              ],
              const SizedBox(height: 16),
              Text('Lines', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: doc.lines.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final line = doc.lines[i];
                    return ListTile(
                      title: Text(
                        line.itemLabel ??
                            (line.itemId == null
                                ? 'Line ${line.id}'
                                : 'Item #${line.itemId}'),
                      ),
                      subtitle: Text(
                        [
                          if (line.quantity != null) 'Qty ${line.quantity}',
                          if (line.requestQty != null) 'Req ${line.requestQty}',
                          if (line.crQty != null) 'Cr ${line.crQty}',
                          if (line.drQty != null) 'Dr ${line.drQty}',
                          if (line.price != null) '@ ${line.price}',
                          if (line.narration != null &&
                              line.narration!.isNotEmpty)
                            line.narration!,
                        ].join(' · '),
                      ),
                      trailing: line.subtotal == null
                          ? null
                          : Text(line.subtotal.toString()),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: Theme.of(context).textTheme.labelMedium),
        Text(v),
      ],
    );
  }
}
