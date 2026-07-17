import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/line_engine/line_engine.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/responsive/breakpoints.dart';
import 'package:algo_erp_front/core/surfaces/document_surface.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/utils/extensions/format_x.dart';
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
          hideLabel: true,
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
        label: 'Qty',
        cellBuilder: (cellCtx, row, i) => AppDecimalField(
          label: 'Qty',
          hideLabel: true,
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
        label: 'Rate',
        cellBuilder: (cellCtx, row, i) => AppDecimalField(
          label: 'Rate',
          hideLabel: true,
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
          hideLabel: true,
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
          hideLabel: true,
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
      LineItemColumn(
        label: 'Amount',
        cellBuilder: (cellCtx, row, i) {
          final amount = row.isComplete
              ? LineEngine.computeLine(
                  LineInput(
                    quantity: row.quantity,
                    price: row.price,
                    discountPercent: row.discountPercent,
                    taxRate: row.taxRate,
                  ),
                ).lineTotal
              : Decimal.zero;
          return AppTextField(
            label: 'Amount',
            hideLabel: true,
            value: amount.toMoney(),
            enabled: false,
          );
        },
      ),
    ];

    return AdaptiveLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TopHeaderBlock(),
          const SizedBox(height: 12),
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
                topBar: const _DocumentTopStrip(),
                rows: rows,
                columns: columns,
                onRowsChanged: (newRows) => context
                    .read<SalesInvoiceFormBloc>()
                    .add(FormRowsChanged(newRows)),
                newRow: SalesInvoiceLine.new,
                keyOf: (row, _) => row.uid,
                lineInputsOf: _lineInput,
                rowSearchFilter: (row, query) =>
                    (row.itemLabel ?? '').toLowerCase().contains(query),
                linesViewportHeight: 240,
                totalsLabel: 'Summary (AED)',
                postLabel: isEdit ? 'Save draft' : 'Post invoice',
                saveDraftCaption: isEdit
                    ? null
                    : 'Save as draft and continue later',
                postCaption: isEdit
                    ? 'Update this draft'
                    : 'Post and update inventory',
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
    return const SizedBox.shrink();
  }
}

class _CustomerField extends StatelessWidget {
  const _CustomerField({this.hideLabel = false});

  final bool hideLabel;

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
      hideLabel: hideLabel,
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

class _TopHeaderBlock extends StatelessWidget {
  const _TopHeaderBlock();

  static const _bp = VoucherBlueprints.salesInvoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isEdit = context.select((SalesInvoiceFormBloc b) => b.state.isEdit);
    final badgeColor = tokens.semanticColors.warning;

    return Container(
      padding: EdgeInsets.all(tokens.spacing.sm),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(tokens.radii.sm),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(_bp.listPath);
              }
            },
          ),
          SizedBox(width: tokens.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: tokens.spacing.sm,
                  runSpacing: tokens.spacing.xs,
                  children: [
                    Text(
                      _bp.label,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: tokens.brand.ink,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spacing.sm,
                        vertical: tokens.spacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(tokens.radii.full),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: badgeColor),
                          SizedBox(width: tokens.spacing.xs),
                          Text(
                            isEdit ? 'Draft' : 'New draft',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: badgeColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: tokens.spacing.xs),
                Text(
                  isEdit
                      ? 'Home › Sales › Invoices › Edit draft'
                      : 'Home › Sales › Invoices › New sales invoice',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.brand.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          if (Breakpoints.isDesktop(context))
            Row(
              children: [
                OutlinedButton(
                  onPressed: null,
                  child: Row(
                    children: [
                      Text('More actions', style: theme.textTheme.labelLarge),
                      SizedBox(width: tokens.spacing.xs),
                      const Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                ),
                SizedBox(width: tokens.spacing.sm),
                OutlinedButton(
                  onPressed: null,
                  child: Row(
                    children: [
                      const Icon(Icons.help_outline, size: 16),
                      SizedBox(width: tokens.spacing.xs),
                      Text('Help', style: theme.textTheme.labelLarge),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Dual top strip: customer AR metrics + invoice metadata card.
class _DocumentTopStrip extends StatelessWidget {
  const _DocumentTopStrip();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (!Breakpoints.isDesktop(context)) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CustomerMetricsBar(),
          SizedBox(height: 12),
          _InvoiceDetailsCard(),
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(flex: 3, child: _CustomerMetricsBar()),
          SizedBox(width: tokens.spacing.sm),
          const Expanded(flex: 2, child: _InvoiceDetailsCard()),
        ],
      ),
    );
  }
}

class _InvoiceDetailsCard extends StatelessWidget {
  const _InvoiceDetailsCard();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: _GodownField()),
                SizedBox(width: tokens.spacing.md),
                const Expanded(child: _VoucherDateField()),
              ],
            ),
            SizedBox(height: tokens.spacing.md),
            Row(
              children: [
                const Expanded(child: _SalesmanField()),
                SizedBox(width: tokens.spacing.md),
                const Expanded(child: _VoucherNoField()),
              ],
            ),
          ],
        ),
      ),
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
      label: 'Godown / warehouse',
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
      label: 'Voucher no.',
      value: prefix.isEmpty ? '—' : prefix,
      enabled: false,
    );
  }
}

class _CustomerMetricsBar extends StatelessWidget {
  const _CustomerMetricsBar();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final customer = context.select(
      (SalesInvoiceFormBloc b) => b.state.customer,
    );

    final hasCustomer = customer != null;
    // Demo AR figures until a customer balance API exists — labeled below.
    final outstanding = hasCustomer ? Decimal.fromInt(25450) : Decimal.zero;
    final creditLimit =
        customer?.credit.creditLimit ??
        (hasCustomer ? Decimal.fromInt(100000) : Decimal.zero);
    final availableCredit = creditLimit - outstanding;

    Widget metricColumn(
      String label,
      String value, {
      Color? valueColor,
      String? subValue,
    }) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.brand.inkMuted,
              ),
            ),
            SizedBox(height: tokens.spacing.xxs),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor ?? tokens.brand.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (subValue != null) ...[
              SizedBox(height: tokens.spacing.xxs),
              Text(
                subValue,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tokens.brand.inkMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Card(
      color: Colors.teal.shade50,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: tokens.spacing.sm,
          horizontal: tokens.spacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: tokens.brand.inkMuted),
                SizedBox(width: tokens.spacing.sm),
                const Expanded(child: _CustomerField(hideLabel: true)),
              ],
            ),
            if (Breakpoints.isDesktop(context)) ...[
              SizedBox(height: tokens.spacing.sm),
              Divider(height: 1, color: tokens.brand.mist),
              SizedBox(height: tokens.spacing.sm),
              Row(
                children: [
                  Expanded(
                    child: metricColumn(
                      'Outstanding',
                      hasCustomer ? 'AED ${outstanding.toMoney()}' : '—',
                      valueColor: hasCustomer
                          ? tokens.semanticColors.danger
                          : null,
                    ),
                  ),
                  Expanded(
                    child: metricColumn(
                      'Credit limit',
                      hasCustomer ? 'AED ${creditLimit.toMoney()}' : '—',
                    ),
                  ),
                  Expanded(
                    child: metricColumn(
                      'Available credit',
                      hasCustomer ? 'AED ${availableCredit.toMoney()}' : '—',
                      valueColor: hasCustomer
                          ? tokens.semanticColors.success
                          : null,
                    ),
                  ),
                  Expanded(
                    child: metricColumn(
                      'Last invoice',
                      hasCustomer ? 'INV-0478' : '—',
                      subValue: hasCustomer ? 'Demo · 12/07/2026' : null,
                    ),
                  ),
                  Expanded(
                    child: metricColumn(
                      'Last payment',
                      hasCustomer ? 'AED 5,000.00' : '—',
                      subValue: hasCustomer ? 'Demo · 10/07/2026' : null,
                    ),
                  ),
                ],
              ),
              if (hasCustomer) ...[
                SizedBox(height: tokens.spacing.xs),
                Text(
                  'AR figures marked Demo until balance API is wired',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tokens.brand.inkMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
