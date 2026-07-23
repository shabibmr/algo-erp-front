import 'dart:typed_data';

import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/tenant_context.dart';
import 'package:algo_erp_front/core/printing/company_header_provider.dart';
import 'package:algo_erp_front/core/printing/voucher_pdf.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/document_pdf_preview_page.dart';
import 'package:algo_erp_front/core/utils/extensions/format_x.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_kind.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_models.dart';
import 'package:algo_erp_front/core/widgets/chips/status_chip.dart';
import 'package:algo_erp_front/core/widgets/dialogs/confirm_dialog.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/transactions_ledger_amount/bloc/ledger_amount_detail_bloc.dart';
import 'package:algo_erp_front/features/transactions_ledger_amount/bloc/ledger_amount_detail_event.dart';
import 'package:algo_erp_front/features/transactions_ledger_amount/bloc/ledger_amount_detail_state.dart';
import 'package:algo_erp_front/features/transactions_ledger_amount/ledger_amount_di.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Read-only detail for Payment / Receipt with cancel powered by flutter_bloc.
class LedgerAmountDetailPage extends StatelessWidget {
  const LedgerAmountDetailPage({
    required this.kind,
    required this.id,
    super.key,
  });

  final LedgerAmountVoucherKind kind;
  final int id;

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<LedgerAmountDetailBloc>(
      create: (_) => LedgerAmountDetailBloc(
        repository: createLedgerAmountRepository(dio, kind),
        ledgerRepository: createLedgerRepository(dio),
      )..add(LedgerAmountDetailFetchRequested(id)),
      child: BlocListener<LedgerAmountDetailBloc, LedgerAmountDetailState>(
        listenWhen: (prev, curr) => prev.actionMessage != curr.actionMessage,
        listener: (context, state) {
          if (state.actionMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.actionMessage!)));
          }
        },
        child: _LedgerAmountDetailView(kind: kind, id: id),
      ),
    );
  }
}

class _LedgerAmountDetailView extends StatelessWidget {
  const _LedgerAmountDetailView({required this.kind, required this.id});

  final LedgerAmountVoucherKind kind;
  final int id;

  Future<void> _cancel(BuildContext context, LedgerAmountDetail doc) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Cancel ${kind.blueprint.label}?',
      message: 'Cancel ${doc.displayNo}? This may reverse GL if posted.',
      confirmLabel: 'Cancel voucher',
      destructive: true,
    );
    if (ok && context.mounted) {
      context.read<LedgerAmountDetailBloc>().add(
        const LedgerAmountDetailCancelled(),
      );
    }
  }

  Future<void> _approve(BuildContext context, LedgerAmountDetail doc) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Approve ${kind.blueprint.label}?',
      message: 'Approve ${doc.displayNo}?',
      confirmLabel: 'Approve',
    );
    if (ok && context.mounted) {
      context.read<LedgerAmountDetailBloc>().add(
        const LedgerAmountDetailApproved(),
      );
    }
  }

  Future<void> _reject(BuildContext context, LedgerAmountDetail doc) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject ${kind.blueprint.label}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason'),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason != null && reason.isNotEmpty && context.mounted) {
      context.read<LedgerAmountDetailBloc>().add(
        LedgerAmountDetailRejected(reason),
      );
    }
  }

  Future<Uint8List> _buildPdf(LedgerAmountDetail doc) async {
    final company = await fetchCurrentCompanyHeader(
      getIt<DioClient>(),
      getIt<TenantContext>(),
    );
    return buildVoucherPdf(
      title: kind.blueprint.label,
      company: company,
      showQtyPrice: false,
      header: PdfDocHeader(
        voucherNo: doc.displayNo,
        dateStr: doc.voucherDate?.toDayString(),
        status: doc.status,
        partyLabel:
            doc.cashBankLabel ??
            (doc.cashBankLedgerId != null ? '#${doc.cashBankLedgerId}' : '—'),
        narration: doc.narration,
      ),
      lines: [
        for (final line in doc.lines)
          PdfDocLine(
            description:
                line.ledgerLabel ??
                (line.ledgerId != null
                    ? '#${line.ledgerId}'
                    : 'Line ${line.id}'),
            amount: line.amount ?? Decimal.zero,
          ),
      ],
      totals: PdfDocTotals(
        total: doc.total ?? Decimal.zero,
        subtotal: doc.total ?? Decimal.zero,
      ),
    );
  }

  void _print(BuildContext context, LedgerAmountDetail doc) {
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
    final bp = kind.blueprint;
    return AdaptiveLayout(
      child: BlocBuilder<LedgerAmountDetailBloc, LedgerAmountDetailState>(
        builder: (context, state) {
          final bloc = context.read<LedgerAmountDetailBloc>();

          if (state.isLoading && state.detail == null) {
            return const LoadingState();
          }
          if (state.isFailure && state.detail == null) {
            return ErrorState(
              failure:
                  state.failure ??
                  const Failure.unknown('Failed to load voucher detail'),
              onRetry: () => bloc.add(LedgerAmountDetailFetchRequested(id)),
            );
          }

          final doc = state.detail;
          if (doc == null) return const LoadingState();

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
                  StatusChip(status: state.entityStatus, label: doc.status),
                  IconButton(
                    tooltip: 'Print',
                    onPressed: () => _print(context, doc),
                    icon: const Icon(Icons.print_outlined),
                  ),
                  if (doc.canApprove)
                    PermissionGate(
                      module: 'Transactions',
                      action: PermissionAction.update,
                      child: FilledButton(
                        onPressed: state.isBusy
                            ? null
                            : () => _approve(context, doc),
                        child: const Text('Approve'),
                      ),
                    ),
                  if (doc.canReject)
                    PermissionGate(
                      module: 'Transactions',
                      action: PermissionAction.update,
                      child: TextButton(
                        onPressed: state.isBusy
                            ? null
                            : () => _reject(context, doc),
                        child: const Text('Reject'),
                      ),
                    ),
                  if (doc.canCancel)
                    PermissionGate(
                      module: 'Transactions',
                      action: PermissionAction.update,
                      child: TextButton(
                        onPressed: state.isBusy
                            ? null
                            : () => _cancel(context, doc),
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
                    _kv(context, 'Date', doc.voucherDate!.toDayString()),
                  if (doc.cashBankLabel != null)
                    _kv(context, 'Cash/Bank', doc.cashBankLabel!),
                  if (doc.total != null)
                    _kv(context, 'Total', doc.total.toString()),
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
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final line = doc.lines[i];
                    return ListTile(
                      title: Text(
                        line.ledgerLabel ??
                            (line.ledgerId == null
                                ? 'Line ${line.id}'
                                : 'Ledger #${line.ledgerId}'),
                      ),
                      subtitle:
                          line.narration == null || line.narration!.isEmpty
                          ? null
                          : Text(line.narration!),
                      trailing: line.amount == null
                          ? null
                          : Text(line.amount.toString()),
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

  Widget _kv(BuildContext context, String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: Theme.of(context).textTheme.labelMedium),
        Text(v),
      ],
    );
  }
}
