import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/line_engine/line_engine.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/responsive/breakpoints.dart';
import 'package:algo_erp_front/core/surfaces/document_surface.dart';
import 'package:algo_erp_front/core/vouchers/voucher_blueprint.dart';
import 'package:algo_erp_front/core/widgets/data_display/line_item_grid.dart';
import 'package:algo_erp_front/core/widgets/fields/app_date_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_decimal_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_number_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/inventory_batch/domain/item_batch.dart';
import 'package:algo_erp_front/features/inventory_batch/item_batch_di.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:algo_erp_front/features/inventory_godown/godown_di.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:algo_erp_front/features/inventory_item/inventory_item_di.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/bloc/sales_invoice_form_bloc.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/bloc/sales_invoice_form_event.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/bloc/sales_invoice_form_state.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/domain/sales_invoice.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/sales_invoice_di.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Built once per module, not per build (see CLAUDE.md). Top-level finals are
// lazy in Dart, so these resolve on first use — after DI is configured — and
// the FK pickers stop allocating a fresh repository on every keystroke.
final DioClient _dio = getIt<DioClient>();
final _invoiceRepo = createSalesInvoiceRepository(_dio);
final _ledgerRepo = createLedgerRepository(_dio);
final _godownRepo = createGodownRepository(_dio);
final _itemRepo = createInventoryItemRepository(_dio);
final _batchRepo = createItemBatchRepository(_dio);

/// Sales Invoice create / Draft-edit form via DocumentSurface + flutter_bloc.
class SalesInvoiceFormPage extends StatelessWidget {
  const SalesInvoiceFormPage({super.key, this.entityId});

  /// When set, loads a Draft SI for edit (`PUT` lifecycle).
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SalesInvoiceFormBloc>(
      create: (_) => SalesInvoiceFormBloc(
        repository: _invoiceRepo,
        ledgerRepository: _ledgerRepo,
        godownRepository: _godownRepo,
        itemRepository: _itemRepo,
      )..add(FormInitialized(entityId: entityId)),
      child: MultiBlocListener(
        listeners: [
          BlocListener<SalesInvoiceFormBloc, SalesInvoiceFormState>(
            listenWhen: (prev, curr) => prev.status != curr.status,
            listener: (context, state) {
              if (state.status == FormSubmissionStatus.success) {
                final verb = state.postedVerb ?? 'Saved';
                final detailText = state.postedVoucherNo != null
                    ? '$verb ${state.postedVoucherNo}'
                    : verb;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(detailText)));
                if (state.postedInvoiceId != null) {
                  context.go(
                    '/transactions/sales-invoices/${state.postedInvoiceId}',
                  );
                }
              }
            },
          ),
        ],
        child: const _SalesInvoiceFormView(),
      ),
    );
  }
}

class _SalesInvoiceFormView extends StatelessWidget {
  const _SalesInvoiceFormView();

  static const _bp = VoucherBlueprints.salesInvoice;

  LineInput? _lineInput(SalesInvoiceLine row) {
    if (!row.isComplete) return null;
    return LineInput(
      quantity: row.quantity,
      price: row.price,
      discountPercent: row.discountPercent,
      taxRate: row.taxRate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select(
      (SalesInvoiceFormBloc b) => b.state.isLoading,
    );
    final isFailure = context.select(
      (SalesInvoiceFormBloc b) => b.state.isFailure,
    );
    final isEdit = context.select((SalesInvoiceFormBloc b) => b.state.isEdit);
    final isPosting = context.select(
      (SalesInvoiceFormBloc b) => b.state.isSubmitting,
    );
    final rows = context.select(
      (SalesInvoiceFormBloc b) => b.state.draft.lines,
    );
    final errorText = context.select(
      (SalesInvoiceFormBloc b) => b.state.errorMessage,
    );
    final entityId = context.select(
      (SalesInvoiceFormBloc b) => b.state.entityId,
    );

    final columns = <LineItemColumn<SalesInvoiceLine>>[
      LineItemColumn(
        label: 'Item',
        flex: 3,
        cellBuilder: (cellCtx, row, i) => FkLookupField<InventoryItem>(
          label: 'Item',
          value: row.itemId == null
              ? null
              : InventoryItem(
                  id: row.itemId!,
                  name: row.itemLabel ?? '',
                  code: '',
                  price: row.price,
                  basePrice: Decimal.zero,
                  standardCost: Decimal.zero,
                  vatRate: row.taxRate,
                  openingStock: Decimal.zero,
                  reorderLevel: Decimal.zero,
                ),
          enabled: !isPosting,
          displayOf: (item) =>
              item.code.isEmpty ? item.name : '${item.code} — ${item.name}',
          loader: (q) async {
            final r = await _itemRepo.list(PageQuery(search: q));
            return r.fold((_) => const [], (p) => p.items);
          },
          onSelected: (item) {
            final updatedLine = item == null
                ? row.copyWith(itemId: null, itemLabel: null, batchId: null)
                : row.copyWith(
                    itemId: item.id,
                    itemLabel: item.name,
                    batchId: null,
                    price: item.price,
                    taxRate: item.vatRate,
                  );
            cellCtx.read<SalesInvoiceFormBloc>().add(
              LineItemUpdated(index: i, line: updatedLine),
            );
          },
        ),
      ),
      LineItemColumn(
        label: 'SKU id',
        cellBuilder: (cellCtx, row, i) => AppNumberField(
          label: 'SKU',
          value: row.skuId,
          enabled: !isPosting,
          helperText: 'Optional',
          onChanged: (v) => cellCtx.read<SalesInvoiceFormBloc>().add(
            LineItemUpdated(
              index: i,
              line: row.copyWith(skuId: v),
            ),
          ),
        ),
      ),
      LineItemColumn(
        label: 'Batch',
        flex: 2,
        cellBuilder: (cellCtx, row, i) => FkLookupField<ItemBatch>(
          label: 'Batch',
          value: row.batchId == null
              ? null
              : ItemBatch(
                  id: row.batchId!,
                  itemId: row.itemId ?? 0,
                  batchNumber: '#${row.batchId}',
                  costPrice: Decimal.zero,
                  sellingPrice: Decimal.zero,
                ),
          enabled: !isPosting && row.itemId != null,
          helperText: row.itemId == null
              ? 'Pick item first'
              : 'Optional — filters by item',
          displayOf: (b) => b.batchNumber,
          loader: (q) async {
            if (row.itemId == null) return const [];
            final r = await _batchRepo.list(
              PageQuery(search: q, filters: {'item_id': row.itemId}),
            );
            return r.fold(
              (_) => const [],
              (p) => p.items
                  .where((b) => b.itemId == row.itemId)
                  .toList(growable: false),
            );
          },
          onSelected: (b) => cellCtx.read<SalesInvoiceFormBloc>().add(
            LineItemUpdated(
              index: i,
              line: row.copyWith(batchId: b?.id),
            ),
          ),
        ),
      ),
      LineItemColumn(
        label: 'Qty',
        cellBuilder: (cellCtx, row, i) => AppDecimalField(
          label: 'Qty',
          value: row.quantity,
          enabled: !isPosting,
          onChanged: (v) => cellCtx.read<SalesInvoiceFormBloc>().add(
            LineItemUpdated(
              index: i,
              line: row.copyWith(quantity: v ?? Decimal.one),
            ),
          ),
        ),
      ),
      LineItemColumn(
        label: 'Price',
        cellBuilder: (cellCtx, row, i) => AppDecimalField(
          label: 'Price',
          value: row.price,
          enabled: !isPosting,
          onChanged: (v) => cellCtx.read<SalesInvoiceFormBloc>().add(
            LineItemUpdated(
              index: i,
              line: row.copyWith(price: v ?? Decimal.zero),
            ),
          ),
        ),
      ),
      LineItemColumn(
        label: 'Disc %',
        cellBuilder: (cellCtx, row, i) => AppDecimalField(
          label: 'Disc %',
          value: row.discountPercent,
          enabled: !isPosting,
          onChanged: (v) => cellCtx.read<SalesInvoiceFormBloc>().add(
            LineItemUpdated(
              index: i,
              line: row.copyWith(discountPercent: v ?? Decimal.zero),
            ),
          ),
        ),
      ),
      LineItemColumn(
        label: 'Tax %',
        cellBuilder: (cellCtx, row, i) => AppDecimalField(
          label: 'Tax %',
          value: row.taxRate,
          enabled: !isPosting,
          onChanged: (v) => cellCtx.read<SalesInvoiceFormBloc>().add(
            LineItemUpdated(
              index: i,
              line: row.copyWith(taxRate: v ?? Decimal.zero),
            ),
          ),
        ),
      ),
    ];

    return AdaptiveLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEdit ? 'Edit draft ${_bp.label}' : 'New ${_bp.label}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Expanded(child: LoadingState())
          else if (isFailure)
            // The draft never loaded: rendering the form anyway would let the
            // user submit an update against a document we don't have.
            Expanded(
              child: ErrorState(
                failure: Failure.unknown(
                  errorText ?? 'Failed to load this invoice',
                ),
                onRetry: () => context.read<SalesInvoiceFormBloc>().add(
                  FormInitialized(entityId: entityId),
                ),
              ),
            )
          else
            Expanded(
              child: DocumentSurface<SalesInvoiceLine>(
                blueprint: _bp,
                header: const _FormHeader(),
                rows: rows,
                columns: columns,
                onRowsChanged: (newRows) => context
                    .read<SalesInvoiceFormBloc>()
                    .add(FormRowsChanged(newRows)),
                newRow: SalesInvoiceLine.new,
                keyOf: (row, _) => row.uid,
                lineInputsOf: _lineInput,
                footer: const _NarrationField(),
                onPost: isEdit
                    ? () => context.read<SalesInvoiceFormBloc>().add(
                        const FormSubmitted(saveStatus: 'Draft'),
                      )
                    : () => context.read<SalesInvoiceFormBloc>().add(
                        const FormSubmitted(saveStatus: 'Posted'),
                      ),
                onSaveDraft: isEdit
                    ? null
                    : () => context.read<SalesInvoiceFormBloc>().add(
                        const FormSubmitted(saveStatus: 'Draft'),
                      ),
                postLabel: isEdit ? 'Save draft' : 'Post',
                posting: isPosting,
                enabled: !isPosting,
                errorText: errorText,
              ),
            ),
        ],
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader();

  @override
  Widget build(BuildContext context) {
    final isEdit = context.select((SalesInvoiceFormBloc b) => b.state.isEdit);
    final sourceType = context.select(
      (SalesInvoiceFormBloc b) => b.state.sourceType,
    );

    return Column(
      children: [
        if (Breakpoints.isDesktop(context)) ...[
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _CustomerField()),
                    SizedBox(width: 12),
                    Expanded(flex: 2, child: _GodownField()),
                    SizedBox(width: 12),
                    Expanded(flex: 2, child: _SalesmanField()),
                  ],
                ),
              ),
              SizedBox(width: 24),
              _VoucherIdentityBlock(),
            ],
          ),
        ] else ...[
          const _VoucherDateField(),
          const SizedBox(height: 12),
          const _VoucherNoField(),
          const SizedBox(height: 12),
          const _CustomerField(),
          const SizedBox(height: 12),
          const _GodownField(),
          const SizedBox(height: 12),
          const _SalesmanField(),
        ],
        const SizedBox(height: 12),
        const _ProjectField(),
        if (!isEdit) ...[
          const SizedBox(height: 12),
          const _SourceTypeDropdown(),
          if (sourceType.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _SourceVoucherField(),
          ],
        ],
        const SizedBox(height: 12),
        const _BillingNameField(),
        const SizedBox(height: 12),
        const _CreditDaysField(),
      ],
    );
  }
}

class _CustomerField extends StatelessWidget {
  const _CustomerField();

  @override
  Widget build(BuildContext context) {
    final customer = context.select(
      (SalesInvoiceFormBloc b) => b.state.customer,
    );
    final isPosting = context.select(
      (SalesInvoiceFormBloc b) => b.state.isSubmitting,
    );

    return FkLookupField<Ledger>(
      label: 'Customer',
      value: customer,
      enabled: !isPosting,
      displayOf: (l) {
        final code = l.code;
        return (code == null || code.isEmpty) ? l.name : '$code — ${l.name}';
      },
      loader: (q) async {
        final r = await _ledgerRepo.list(PageQuery(search: q));
        return r.fold((_) => const [], (p) => p.items);
      },
      onSelected: (l) =>
          context.read<SalesInvoiceFormBloc>().add(CustomerSelected(l)),
      validator: (v) => v == null ? 'Customer is required' : null,
    );
  }
}

class _GodownField extends StatelessWidget {
  const _GodownField();

  @override
  Widget build(BuildContext context) {
    final godown = context.select((SalesInvoiceFormBloc b) => b.state.godown);
    final isPosting = context.select(
      (SalesInvoiceFormBloc b) => b.state.isSubmitting,
    );

    return FkLookupField<Godown>(
      label: 'Godown',
      value: godown,
      enabled: !isPosting,
      displayOf: (g) => g.name,
      loader: (q) async {
        final r = await _godownRepo.list(PageQuery(search: q));
        return r.fold((_) => const [], (p) => p.items);
      },
      onSelected: (g) =>
          context.read<SalesInvoiceFormBloc>().add(GodownSelected(g)),
      validator: (v) => v == null ? 'Godown is required' : null,
    );
  }
}

class _SalesmanField extends StatelessWidget {
  const _SalesmanField();

  @override
  Widget build(BuildContext context) {
    final salesperson = context.select(
      (SalesInvoiceFormBloc b) => b.state.salesperson,
    );
    final isPosting = context.select(
      (SalesInvoiceFormBloc b) => b.state.isSubmitting,
    );

    return FkLookupField<EmployeeLite>(
      label: 'Salesman',
      value: salesperson,
      enabled: !isPosting,
      displayOf: (e) => e.label,
      loader: (q) async {
        final r = await _invoiceRepo.searchEmployees(q);
        return r.fold((_) => const [], (list) => list);
      },
      onSelected: (e) =>
          context.read<SalesInvoiceFormBloc>().add(SalespersonSelected(e)),
    );
  }
}

class _ProjectField extends StatelessWidget {
  const _ProjectField();

  @override
  Widget build(BuildContext context) {
    final project = context.select((SalesInvoiceFormBloc b) => b.state.project);
    final isPosting = context.select(
      (SalesInvoiceFormBloc b) => b.state.isSubmitting,
    );

    return FkLookupField<ProjectLite>(
      label: 'Project',
      value: project,
      enabled: !isPosting,
      displayOf: (p) => p.label,
      loader: (q) async {
        final r = await _invoiceRepo.searchProjects(q);
        return r.fold((_) => const [], (list) => list);
      },
      onSelected: (p) =>
          context.read<SalesInvoiceFormBloc>().add(ProjectSelected(p)),
    );
  }
}

class _VoucherDateField extends StatelessWidget {
  const _VoucherDateField();

  @override
  Widget build(BuildContext context) {
    final voucherDate = context.select(
      (SalesInvoiceFormBloc b) => b.state.draft.voucherDate,
    );
    final isPosting = context.select(
      (SalesInvoiceFormBloc b) => b.state.isSubmitting,
    );

    return AppDateField(
      label: 'Voucher date',
      value: voucherDate,
      enabled: !isPosting,
      onChanged: (d) {
        if (d != null) {
          context.read<SalesInvoiceFormBloc>().add(VoucherDateChanged(d));
        }
      },
    );
  }
}

class _VoucherNoField extends StatelessWidget {
  const _VoucherNoField();

  @override
  Widget build(BuildContext context) {
    final prefix = context.select(
      (SalesInvoiceFormBloc b) => b.state.draft.voucherPrefix,
    );

    return AppTextField(
      label: 'Voucher No.',
      value: prefix,
      enabled: false,
      helperText: 'Auto-numbered on post',
    );
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(label),
            ),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }
}

class _VoucherIdentityBlock extends StatelessWidget {
  const _VoucherIdentityBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IdentityRow(label: 'Voucher date', value: _VoucherDateField()),
        SizedBox(height: 12),
        _IdentityRow(label: 'Voucher No.', value: _VoucherNoField()),
      ],
    );
  }
}

class _SourceTypeDropdown extends StatelessWidget {
  const _SourceTypeDropdown();

  @override
  Widget build(BuildContext context) {
    final sourceType = context.select(
      (SalesInvoiceFormBloc b) => b.state.sourceType,
    );
    final isPosting = context.select(
      (SalesInvoiceFormBloc b) => b.state.isSubmitting,
    );

    return DropdownButtonFormField<String>(
      initialValue: sourceType,
      decoration: const InputDecoration(
        labelText: 'Convert from',
        helperText: 'Optional Quotation / Sales Order conversion',
      ),
      items: const [
        DropdownMenuItem(value: '', child: Text('None')),
        DropdownMenuItem(value: 'SalesOrder', child: Text('Sales order')),
        DropdownMenuItem(value: 'Quotation', child: Text('Quotation')),
      ],
      onChanged: isPosting
          ? null
          : (v) => context.read<SalesInvoiceFormBloc>().add(
              SourceTypeChanged(v ?? ''),
            ),
    );
  }
}

class _SourceVoucherField extends StatelessWidget {
  const _SourceVoucherField();

  @override
  Widget build(BuildContext context) {
    final sourceType = context.select(
      (SalesInvoiceFormBloc b) => b.state.sourceType,
    );
    final source = context.select((SalesInvoiceFormBloc b) => b.state.source);
    final isPosting = context.select(
      (SalesInvoiceFormBloc b) => b.state.isSubmitting,
    );

    return FkLookupField<SourceVoucherLite>(
      label: 'Source $sourceType',
      value: source,
      enabled: !isPosting,
      helperText: 'Loads customer, godown, and lines',
      displayOf: (s) => '${s.type} ${s.displayNo}',
      loader: (q) async {
        final r = await _invoiceRepo.searchSourceVouchers(
          type: sourceType,
          query: q,
        );
        return r.fold((_) => const [], (list) => list);
      },
      onSelected: (s) =>
          context.read<SalesInvoiceFormBloc>().add(SourceVoucherSelected(s)),
    );
  }
}

class _BillingNameField extends StatelessWidget {
  const _BillingNameField();

  @override
  Widget build(BuildContext context) {
    final billingName = context.select(
      (SalesInvoiceFormBloc b) => b.state.draft.billingName,
    );
    final isPosting = context.select(
      (SalesInvoiceFormBloc b) => b.state.isSubmitting,
    );

    return AppTextField(
      label: 'Billing name',
      value: billingName,
      enabled: !isPosting,
      onChanged: (v) =>
          context.read<SalesInvoiceFormBloc>().add(BillingNameChanged(v)),
    );
  }
}

class _CreditDaysField extends StatelessWidget {
  const _CreditDaysField();

  @override
  Widget build(BuildContext context) {
    final creditDays = context.select(
      (SalesInvoiceFormBloc b) => b.state.draft.creditDays,
    );
    final isPosting = context.select(
      (SalesInvoiceFormBloc b) => b.state.isSubmitting,
    );

    return AppNumberField(
      label: 'Credit days',
      value: creditDays,
      enabled: !isPosting,
      onChanged: (v) =>
          context.read<SalesInvoiceFormBloc>().add(CreditDaysChanged(v)),
    );
  }
}

class _NarrationField extends StatelessWidget {
  const _NarrationField();

  @override
  Widget build(BuildContext context) {
    final narration = context.select(
      (SalesInvoiceFormBloc b) => b.state.draft.narration,
    );
    final isPosting = context.select(
      (SalesInvoiceFormBloc b) => b.state.isSubmitting,
    );

    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.5,
      child: AppTextField(
        label: 'Narration',
        value: narration,
        enabled: !isPosting,
        maxLines: 4,
        onChanged: (v) =>
            context.read<SalesInvoiceFormBloc>().add(NarrationChanged(v)),
      ),
    );
  }
}
