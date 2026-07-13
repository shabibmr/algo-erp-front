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
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_kind.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_models.dart';
import 'package:algo_erp_front/core/widgets/chips/status_chip.dart';
import 'package:algo_erp_front/core/widgets/dialogs/confirm_dialog.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/inventory_godown/godown_di.dart';
import 'package:algo_erp_front/features/inventory_item/inventory_item_di.dart';
import 'package:algo_erp_front/features/transactions_item_qty/bloc/item_qty_detail_bloc.dart';
import 'package:algo_erp_front/features/transactions_item_qty/bloc/item_qty_detail_event.dart';
import 'package:algo_erp_front/features/transactions_item_qty/bloc/item_qty_detail_state.dart';
import 'package:algo_erp_front/features/transactions_item_qty/item_qty_di.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Read-only detail for an [ItemQtyVoucherKind] with cancel lifecycle powered by flutter_bloc.
class ItemQtyDetailPage extends StatelessWidget {
  const ItemQtyDetailPage({required this.kind, required this.id, super.key});

  final ItemQtyVoucherKind kind;
  final int id;

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<ItemQtyDetailBloc>(
      create: (_) => ItemQtyDetailBloc(
        repository: createItemQtyRepository(dio, kind),
        itemRepository: createInventoryItemRepository(dio),
        ledgerRepository: createLedgerRepository(dio),
        godownRepository: createGodownRepository(dio),
      )..add(ItemQtyDetailFetchRequested(id)),
      child: BlocListener<ItemQtyDetailBloc, ItemQtyDetailState>(
        listenWhen: (prev, curr) => prev.actionMessage != curr.actionMessage,
        listener: (context, state) {
          if (state.actionMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.actionMessage!)));
          }
        },
        child: _ItemQtyDetailView(kind: kind, id: id),
      ),
    );
  }
}

class _ItemQtyDetailView extends StatelessWidget {
  const _ItemQtyDetailView({required this.kind, required this.id});

  final ItemQtyVoucherKind kind;
  final int id;

  Future<void> _cancel(BuildContext context, ItemQtyDetail doc) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Cancel ${kind.blueprint.label}?',
      message: 'Cancel ${doc.displayNo}? This may reverse stock/GL if posted.',
      confirmLabel: 'Cancel voucher',
      destructive: true,
    );
    if (ok && context.mounted) {
      context.read<ItemQtyDetailBloc>().add(const ItemQtyDetailCancelled());
    }
  }

  Future<Uint8List> _buildPdf(ItemQtyDetail doc) async {
    final company = await fetchCurrentCompanyHeader(
      getIt<DioClient>(),
      getIt<TenantContext>(),
    );
    return buildVoucherPdf(
      title: kind.blueprint.label,
      company: company,
      header: PdfDocHeader(
        voucherNo: doc.displayNo,
        dateStr: doc.voucherDate?.toDayString(),
        status: doc.status,
        partyLabel:
            doc.partyLabel ??
            doc.billingName ??
            (doc.partyLedgerId != null ? '#${doc.partyLedgerId}' : '—'),
        narration: doc.narration,
      ),
      lines: [
        for (final line in doc.lines)
          PdfDocLine(
            description:
                line.itemLabel ??
                (line.itemId != null ? '#${line.itemId}' : 'Line ${line.id}'),
            qty: line.quantity?.toQuantity(),
            price: line.price?.toMoney(),
            amount:
                (line.subtotal ?? Decimal.zero) +
                (line.taxAmount ?? Decimal.zero),
          ),
      ],
      totals: PdfDocTotals(
        total: doc.total ?? Decimal.zero,
        subtotal: doc.total ?? Decimal.zero,
        discount: doc.discount,
        vat: doc.vat,
      ),
    );
  }

  void _print(BuildContext context, ItemQtyDetail doc) {
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
      child: BlocBuilder<ItemQtyDetailBloc, ItemQtyDetailState>(
        builder: (context, state) {
          final bloc = context.read<ItemQtyDetailBloc>();

          if (state.isLoading && state.detail == null) {
            return const LoadingState();
          }
          if (state.isFailure && state.detail == null) {
            return ErrorState(
              failure:
                  state.failure ??
                  const Failure.unknown('Failed to load voucher detail'),
              onRetry: () => bloc.add(ItemQtyDetailFetchRequested(id)),
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
                  if (doc.canCancel && doc.status != 'Cancelled')
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
                  if (doc.partyLabel != null || doc.billingName != null)
                    _kv(
                      context,
                      kind.partyLabel,
                      doc.partyLabel ?? doc.billingName ?? '',
                    ),
                  if (doc.godownLabel != null)
                    _kv(context, 'Godown', doc.godownLabel!),
                  if (doc.total != null)
                    _kv(context, 'Total', doc.total.toString()),
                  if (doc.discount != null)
                    _kv(context, 'Discount', doc.discount.toString()),
                  if (doc.vat != null) _kv(context, 'VAT', doc.vat.toString()),
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
                        line.itemLabel ??
                            (line.itemId == null
                                ? 'Line ${line.id}'
                                : 'Item #${line.itemId}'),
                      ),
                      subtitle: Text(
                        [
                          if (line.quantity != null) 'Qty ${line.quantity}',
                          if (line.price != null) '@ ${line.price}',
                          if (line.discountPercent != null)
                            'Disc ${line.discountPercent}%',
                          if (line.taxRate != null) 'Tax ${line.taxRate}%',
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
