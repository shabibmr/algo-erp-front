import 'dart:typed_data';

import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/tenant_context.dart';
import 'package:algo_erp_front/core/printing/company_header_provider.dart';
import 'package:algo_erp_front/core/printing/voucher_pdf.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/document_pdf_preview_page.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/utils/extensions/format_x.dart';
import 'package:algo_erp_front/core/vouchers/voucher_blueprint.dart';
import 'package:algo_erp_front/core/widgets/chips/status_chip.dart';
import 'package:algo_erp_front/core/widgets/dialogs/confirm_dialog.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/inventory_godown/godown_di.dart';
import 'package:algo_erp_front/features/inventory_item/inventory_item_di.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/data/sales_invoice_dto.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/domain/sales_invoice.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/sales_invoice_di.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Read-only SI detail with approve / reject / cancel / post-and-book.
///
/// Lifecycle RBAC uses coarse `Transactions:update` (backend routes).
class SalesInvoiceDetailPage extends StatefulWidget {
  const SalesInvoiceDetailPage({required this.id, super.key});

  final int id;

  @override
  State<SalesInvoiceDetailPage> createState() => _SalesInvoiceDetailPageState();
}

class _SalesInvoiceDetailPageState extends State<SalesInvoiceDetailPage> {
  static const _bp = VoucherBlueprints.salesInvoice;

  late final _repo = createSalesInvoiceRepository(getIt<DioClient>());
  late final _itemRepo = createInventoryItemRepository(getIt<DioClient>());
  late final _ledgerRepo = createLedgerRepository(getIt<DioClient>());
  late final _godownRepo = createGodownRepository(getIt<DioClient>());
  Future<SalesInvoiceDetail>? _future;
  bool _busy = false;
  bool? _seriesRequiresApproval;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() => _future = _load());
  }

  Future<SalesInvoiceDetail> _load() async {
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
      resolveCustomerLabel: (ledgerId) async {
        final r = await _ledgerRepo.getById(ledgerId);
        return r.fold((_) => null, (l) {
          final code = l.code;
          return (code == null || code.isEmpty) ? l.name : '$code — ${l.name}';
        });
      },
      resolveGodownLabel: (godownId) async {
        final r = await _godownRepo.getById(godownId);
        return r.fold((_) => null, (g) => g.name);
      },
      resolveSalespersonLabel: (employeeId) async {
        final r = await _repo.getEmployee(employeeId);
        return r.fold((_) => null, (e) => e?.label);
      },
      resolveProjectLabel: (projectId) async {
        final r = await _repo.getProject(projectId);
        return r.fold((_) => null, (p) => p?.label);
      },
    );
    final detail = result.fold((f) => throw Exception(f.toString()), (d) => d);
    final series = await _repo.seriesRequiresApproval(
      voucherType: 'SalesInvoice',
      prefix: detail.voucherPrefix.isEmpty ? 'SI' : detail.voucherPrefix,
    );
    series.fold((_) {}, (flag) {
      if (mounted) setState(() => _seriesRequiresApproval = flag);
    });
    return detail;
  }

  EntityStatus _entityStatus(String status) => switch (status) {
    'Draft' => EntityStatus.draft,
    'Approved' => EntityStatus.approved,
    'Posted' => EntityStatus.posted,
    'Cancelled' => EntityStatus.cancelled,
    'Rejected' => EntityStatus.rejected,
    _ => EntityStatus.draft,
  };

  String _msg(Failure f) => switch (f) {
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

  Future<void> _runLifecycle(
    Future<Result<VoucherLifecycleResult>> Function() action,
    String successHint,
  ) async {
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_msg(failure))));
      },
      (ok) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok.message ?? '$successHint → ${ok.status}')),
        );
        _reload();
      },
    );
  }

  Future<void> _approve() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Approve sales invoice?',
      message:
          'Advances status per voucher series (Draft→Approved or →Posted). '
          'When status becomes Posted, the server books GL, stock, and '
          'billwise if not already posted (idempotent).',
      confirmLabel: 'Approve',
    );
    if (!ok || !mounted) return;
    await _runLifecycle(() => _repo.approve(widget.id), 'Approved');
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject sales invoice'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Required',
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || !mounted) return;
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rejection reason is required')),
      );
      return;
    }
    await _runLifecycle(() => _repo.reject(widget.id, reason), 'Rejected');
  }

  Future<void> _cancel() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Cancel sales invoice?',
      message:
          'Reverses GL and stock for Posted documents where applicable. '
          'This cannot be undone.',
      confirmLabel: 'Cancel voucher',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _runLifecycle(() => _repo.cancel(widget.id), 'Cancelled');
  }

  /// Legacy fallback: books GL/stock by creating a **new** Posted invoice.
  /// Prefer Approve (server now books on Draft/Approved → Posted).
  Future<void> _postAndBook(SalesInvoiceDetail doc) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Post & book as new invoice?',
      message:
          'Creates a new Posted sales invoice (new number) with GL and stock. '
          'This document stays unchanged. Prefer Approve when the series '
          'should advance this voucher to Posted.',
      confirmLabel: 'Post & book',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final draft = SalesInvoiceDto.detailToDraft(doc, saveStatus: 'Posted');
    final result = await _repo.post(draft);
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_msg(failure))));
      },
      (posted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booked ${posted.voucherNo} · original #${doc.id} unchanged',
            ),
          ),
        );
        context.go('/transactions/sales-invoices/${posted.id}');
      },
    );
  }

  Future<Uint8List> _buildPdf(SalesInvoiceDetail doc) async {
    final company = await fetchCurrentCompanyHeader(
      getIt<DioClient>(),
      getIt<TenantContext>(),
    );
    return buildVoucherPdf(
      title: _bp.label,
      company: company,
      header: PdfDocHeader(
        voucherNo: doc.displayNo,
        dateStr: doc.voucherDate?.toDayString(),
        status: doc.status,
        partyLabel:
            doc.customerLabel ??
            doc.billingName ??
            (doc.customerLedgerId != null ? '#${doc.customerLedgerId}' : '—'),
        narration: doc.narration,
      ),
      lines: [
        for (final line in doc.lines)
          PdfDocLine(
            description:
                line.itemLabel ??
                (line.itemId != null ? '#${line.itemId}' : '—'),
            qty: line.quantity?.toQuantity(),
            price: line.price?.toMoney(),
            amount:
                (line.subtotal ?? Decimal.zero) +
                (line.taxAmount ?? Decimal.zero),
          ),
      ],
      totals: PdfDocTotals(
        subtotal: doc.total ?? Decimal.zero,
        discount: doc.discount,
        vat: doc.vat,
        total: doc.grossTotal ?? doc.total ?? Decimal.zero,
      ),
    );
  }

  void _print(SalesInvoiceDetail doc) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DocumentPdfPreviewPage(
          title: 'Print ${doc.displayNo}',
          pdfBuilder: () => _buildPdf(doc),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AdaptiveLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () => context.go(_bp.listPath),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  _bp.label,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<SalesInvoiceDetail>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const LoadingState();
                }
                if (snapshot.hasError) {
                  final err = snapshot.error;
                  return ErrorState(
                    failure: err is Failure
                        ? err
                        : Failure.unknown(err.toString()),
                    onRetry: _reload,
                  );
                }
                final doc = snapshot.data;
                if (doc == null) return const LoadingState();
                return _DetailBody(
                  doc: doc,
                  busy: _busy,
                  entityStatus: _entityStatus(doc.status),
                  seriesRequiresApproval: _seriesRequiresApproval,
                  onEdit: doc.canEditDraft
                      ? () => context.push(
                          '/transactions/sales-invoices/${doc.id}/edit',
                        )
                      : null,
                  onPostAndBook: doc.canPostAndBook
                      ? () => _postAndBook(doc)
                      : null,
                  onApprove: doc.canApprove ? _approve : null,
                  onReject: doc.canReject ? _reject : null,
                  onCancel: doc.canCancel ? _cancel : null,
                  onPrint: () => _print(doc),
                  spacing: tokens.spacing.md,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.doc,
    required this.busy,
    required this.entityStatus,
    required this.spacing,
    this.seriesRequiresApproval,
    this.onEdit,
    this.onPostAndBook,
    this.onApprove,
    this.onReject,
    this.onCancel,
    this.onPrint,
  });

  static const _bp = VoucherBlueprints.salesInvoice;

  final SalesInvoiceDetail doc;
  final bool busy;
  final EntityStatus entityStatus;
  final double spacing;
  final bool? seriesRequiresApproval;
  final VoidCallback? onEdit;
  final VoidCallback? onPostAndBook;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;
  final VoidCallback? onPrint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(doc.displayNo, style: theme.textTheme.titleLarge),
              ),
              StatusChip(status: entityStatus, label: doc.status),
            ],
          ),
          if (doc.status == 'Draft' || doc.status == 'Approved') ...[
            SizedBox(height: spacing),
            _ApprovalBanner(
              status: doc.status,
              seriesRequiresApproval: seriesRequiresApproval,
              prefix: doc.voucherPrefix,
            ),
          ],
          SizedBox(height: spacing),
          _kv('Date', doc.voucherDate?.toDayString() ?? '—'),
          _kv(
            'Customer',
            doc.customerLabel ??
                doc.billingName ??
                (doc.customerLedgerId != null
                    ? '#${doc.customerLedgerId}'
                    : '—'),
          ),
          if (doc.billingName != null && doc.billingName != doc.customerLabel)
            _kv('Billing name', doc.billingName!),
          _kv(
            'Godown',
            doc.godownLabel ??
                (doc.godownId != null ? '#${doc.godownId}' : '—'),
          ),
          if (doc.salespersonEmployeeId != null)
            _kv(
              'Salesperson',
              doc.salespersonLabel ?? '#${doc.salespersonEmployeeId}',
            ),
          if (doc.voucherProjectId != null)
            _kv('Project', doc.projectLabel ?? '#${doc.voucherProjectId}'),
          if (doc.narration != null && doc.narration!.isNotEmpty)
            _kv('Narration', doc.narration!),
          if (doc.rejectionReason != null && doc.rejectionReason!.isNotEmpty)
            _kv('Rejection reason', doc.rejectionReason!),
          SizedBox(height: spacing),
          Text('Lines', style: theme.textTheme.titleMedium),
          SizedBox(height: spacing / 2),
          if (doc.lines.isEmpty)
            const Text('No lines')
          else
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Item')),
                    DataColumn(label: Text('Qty'), numeric: true),
                    DataColumn(label: Text('Price'), numeric: true),
                    DataColumn(label: Text('Disc %'), numeric: true),
                    DataColumn(label: Text('Tax %'), numeric: true),
                    DataColumn(label: Text('Subtotal'), numeric: true),
                    DataColumn(label: Text('Tax'), numeric: true),
                  ],
                  rows: [
                    for (final line in doc.lines)
                      DataRow(
                        cells: [
                          DataCell(
                            Text(
                              line.itemLabel ??
                                  (line.itemId != null
                                      ? '#${line.itemId}'
                                      : '—'),
                            ),
                          ),
                          DataCell(Text(_d(line.quantity))),
                          DataCell(Text(_d(line.price))),
                          DataCell(Text(_d(line.discountPercent))),
                          DataCell(Text(_d(line.taxRate))),
                          DataCell(Text(_d(line.subtotal))),
                          DataCell(Text(_d(line.taxAmount))),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          SizedBox(height: spacing),
          Card(
            child: Padding(
              padding: EdgeInsets.all(spacing),
              child: Column(
                children: [
                  _moneyRow(context, 'Subtotal', doc.total),
                  _moneyRow(context, 'Discount', doc.discount),
                  _moneyRow(context, 'VAT', doc.vat),
                  const Divider(),
                  _moneyRow(
                    context,
                    'Total',
                    doc.grossTotal ?? doc.total,
                    emphasize: true,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onPrint != null)
                OutlinedButton.icon(
                  onPressed: busy ? null : onPrint,
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print'),
                ),
              if (onEdit != null)
                PermissionGate(
                  module: _bp.rbacModule,
                  action: PermissionAction.update,
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit draft'),
                  ),
                ),
              if (onPostAndBook != null)
                PermissionGate(
                  module: _bp.rbacModule,
                  action: PermissionAction.create,
                  child: FilledButton.icon(
                    onPressed: busy ? null : onPostAndBook,
                    icon: const Icon(Icons.account_balance_outlined),
                    label: const Text('Post & book'),
                  ),
                ),
              if (onApprove != null)
                PermissionGate(
                  module: 'Transactions',
                  action: PermissionAction.update,
                  child: FilledButton(
                    onPressed: busy ? null : onApprove,
                    child: const Text('Approve'),
                  ),
                ),
              if (onReject != null)
                PermissionGate(
                  module: 'Transactions',
                  action: PermissionAction.update,
                  child: OutlinedButton(
                    onPressed: busy ? null : onReject,
                    child: const Text('Reject'),
                  ),
                ),
              if (onCancel != null)
                PermissionGate(
                  module: 'Transactions',
                  action: PermissionAction.update,
                  child: OutlinedButton(
                    onPressed: busy ? null : onCancel,
                    child: Text(
                      'Cancel voucher',
                      style: TextStyle(color: tokens.semanticColors.danger),
                    ),
                  ),
                ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _d(Decimal? v) => v?.toString() ?? '—';

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(k, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Expanded(child: Text(v)),
      ],
    ),
  );

  Widget _moneyRow(
    BuildContext context,
    String label,
    Decimal? value, {
    bool emphasize = false,
  }) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value?.toMoney() ?? '—', style: style),
        ],
      ),
    );
  }
}

class _ApprovalBanner extends StatelessWidget {
  const _ApprovalBanner({
    required this.status,
    required this.seriesRequiresApproval,
    required this.prefix,
  });

  final String status;
  final bool? seriesRequiresApproval;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final String body;
    if (status == 'Draft') {
      if (seriesRequiresApproval ?? false) {
        body =
            'Series "$prefix" requires approval: Draft → Approved → Posted. '
            'When Approve reaches Posted, the server books GL, stock, and '
            'billwise if not already booked.';
      } else if (seriesRequiresApproval == false) {
        body =
            'Series "$prefix" has approval off: Approve sets Posted and books '
            'GL/stock/billwise on this voucher (idempotent).';
      } else {
        body =
            'Draft has no GL/stock until Posted. Approve advances status per '
            'series; reaching Posted books accounts on this voucher.';
      }
    } else {
      body = (seriesRequiresApproval ?? false)
          ? 'Approved — Approve again to set Posted and book GL/stock if '
                'not already booked.'
          : 'Approved — Approve sets Posted and books GL/stock if needed.';
    }
    return Container(
      padding: EdgeInsets.all(tokens.spacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(tokens.radii.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          SizedBox(width: tokens.spacing.sm),
          Expanded(
            child: Text(
              body,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
