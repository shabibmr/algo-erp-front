import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/line_engine/line_engine.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/responsive/breakpoints.dart';
import 'package:algo_erp_front/core/surfaces/document_surface.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/utils/extensions/format_x.dart';
import 'package:algo_erp_front/core/vouchers/voucher_blueprint.dart';
import 'package:algo_erp_front/core/widgets/chips/status_chip.dart';
import 'package:algo_erp_front/core/widgets/data_display/line_item_columns.dart';
import 'package:algo_erp_front/core/widgets/data_display/line_item_grid.dart';
import 'package:algo_erp_front/core/widgets/dialogs/confirm_dialog.dart';
import 'package:algo_erp_front/core/widgets/dialogs/variant_picker_dialog.dart';
import 'package:algo_erp_front/core/widgets/fields/app_date_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_dropdown_field.dart';
import 'package:algo_erp_front/core/widgets/layout/field_widths.dart';
import 'package:algo_erp_front/core/widgets/layout/page_header.dart';
import 'package:algo_erp_front/core/widgets/layout/work_sheet.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_loaders.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:algo_erp_front/features/inventory_godown/godown_di.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:algo_erp_front/features/inventory_item/inventory_item_di.dart';
import 'package:algo_erp_front/features/inventory_pricelist/domain/price_list.dart';
import 'package:algo_erp_front/features/inventory_pricelist/price_list_di.dart';
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
final _priceListRepo = createPriceListRepository(_dio);

/// Asks the user to confirm abandoning an in-progress invoice. Returns `true`
/// when they choose to leave. Shared by the back button and the [PopScope]
/// guard so both routes out of the form behave identically.
Future<bool> _confirmDiscardInvoice(BuildContext context) {
  return showConfirmDialog(
    context,
    title: 'Discard this invoice?',
    message: 'You have unsaved changes. Leaving now discards them.',
    confirmLabel: 'Discard',
    cancelLabel: 'Keep editing',
    destructive: true,
  );
}

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
    return row.toLineInput();
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
    final isDirty = context.select((SalesInvoiceFormBloc b) => b.state.isDirty);

    final columns = <LineItemColumn<SalesInvoiceLine>>[
      LineItemColumn(
        label: 'Item',
        flex: 3,
        cellBuilder: (cellCtx, row, i) => FkLookupField<InventoryItem>(
          label: 'Item',
          hideLabel: true,
          isBorderless: true,
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
          loader: pagedLookup(_itemRepo),
          onSelected: (item) async {
            final bloc = cellCtx.read<SalesInvoiceFormBloc>();
            if (item == null) {
              bloc.add(
                LineItemUpdated(
                  index: i,
                  line: row.copyWith(
                    itemId: null,
                    itemLabel: null,
                    itemCode: null,
                    batchId: null,
                  ),
                ),
              );
              return;
            }
            final price = await bloc.resolveLinePrice(item);
            if (!cellCtx.mounted) return;
            bloc.add(
              LineItemUpdated(
                index: i,
                line: row.copyWith(
                  itemId: item.id,
                  itemLabel: item.name,
                  itemCode: item.code,
                  batchId: null,
                  price: price,
                  taxRate: item.vatRate,
                  priceLevel: bloc.priceLevelStamp(),
                ),
              ),
            );
          },
        ),
      ),

      LineItemColumn(
        label: 'Variant / SKU',
        flex: 2,
        cellBuilder: (cellCtx, row, i) {
          if (row.itemId == null) {
            return const SizedBox.shrink();
          }
          final hasVariant = row.skuId != null;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isPosting
                      ? null
                      : () async {
                          final result = await VariantPickerDialog.show(
                            cellCtx,
                            itemId: row.itemId!,
                            itemName: row.itemLabel ?? 'Item',
                            itemCode: row.itemCode,
                            currentSkuId: row.skuId,
                          );
                          if (result != null) {
                            cellCtx.read<SalesInvoiceFormBloc>().add(
                              LineItemUpdated(
                                index: i,
                                line: row.copyWith(
                                  skuId: result.skuId,
                                  skuCode: result.skuCode,
                                  skuLabel: result.attributeSummary.isNotEmpty
                                      ? result.attributeSummary
                                      : result.skuCode,
                                  price: result.rate != null
                                      ? Decimal.parse(result.rate!.toString())
                                      : row.price,
                                ),
                              ),
                            );
                          }
                        },
                  icon: Icon(
                    hasVariant ? Icons.check_circle : Icons.tune,
                    size: 14,
                    color: hasVariant ? Colors.green : null,
                  ),
                  label: Text(
                    row.skuLabel ?? row.skuCode ?? 'Select Variant',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              if (hasVariant)
                IconButton(
                  icon: const Icon(Icons.clear, size: 14),
                  tooltip: 'Clear variant',
                  onPressed: isPosting
                      ? null
                      : () {
                          cellCtx.read<SalesInvoiceFormBloc>().add(
                            LineItemUpdated(
                              index: i,
                              line: row.copyWith(
                                skuId: null,
                                skuCode: null,
                                skuLabel: null,
                              ),
                            ),
                          );
                        },
                ),
            ],
          );
        },
      ),

      decimalColumn<SalesInvoiceLine>(
        label: 'Qty',
        get: (r) => r.quantity,
        set: (r, v) => r.copyWith(quantity: v),
        fallback: Decimal.one,
        enabled: !isPosting,
        onChanged: (ctx, i, line) => ctx.read<SalesInvoiceFormBloc>().add(
          LineItemUpdated(index: i, line: line),
        ),
      ),
      decimalColumn<SalesInvoiceLine>(
        label: 'Rate',
        get: (r) => r.price,
        set: (r, v) => r.copyWith(price: v),
        enabled: !isPosting,
        onChanged: (ctx, i, line) => ctx.read<SalesInvoiceFormBloc>().add(
          LineItemUpdated(index: i, line: line),
        ),
      ),
      decimalColumn<SalesInvoiceLine>(
        label: 'Disc %',
        get: (r) => r.discountPercent,
        set: (r, v) => r.copyWith(discountPercent: v),
        enabled: !isPosting,
        onChanged: (ctx, i, line) => ctx.read<SalesInvoiceFormBloc>().add(
          LineItemUpdated(index: i, line: line),
        ),
      ),
      decimalColumn<SalesInvoiceLine>(
        label: 'Tax %',
        get: (r) => r.taxRate,
        set: (r, v) => r.copyWith(taxRate: v),
        enabled: !isPosting,
        onChanged: (ctx, i, line) => ctx.read<SalesInvoiceFormBloc>().add(
          LineItemUpdated(index: i, line: line),
        ),
      ),
      moneyColumn<SalesInvoiceLine>(
        label: 'Amount',
        amount: (row) => row.isComplete
            ? LineEngine.computeLine(
                LineInput(
                  quantity: row.quantity,
                  price: row.price,
                  discountPercent: row.discountPercent,
                  taxRate: row.taxRate,
                ),
              ).lineTotal
            : Decimal.zero,
      ),
    ];

    return PopScope(
      // Block a system/predictive back (or browser back) while there are
      // unsaved changes; the callback confirms, then pops imperatively (which
      // bypasses this guard, so there's no loop). A blank or just-saved form
      // has isDirty == false and pops straight through.
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final leave = await _confirmDiscardInvoice(context);
        if (leave) navigator.pop();
      },
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TopHeaderBlock(),
            SizedBox(height: context.tokens.spacing.md),
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
                  topBar: const _DocumentTopStrip(),
                  rows: rows,
                  columns: columns,
                  onRowsChanged: (newRows) => context
                      .read<SalesInvoiceFormBloc>()
                      .add(FormRowsChanged(newRows)),
                  newRow: ItemQtyLine.new,
                  keyOf: (row, _) => row.uid,
                  lineInputsOf: _lineInput,
                  rowSearchFilter: (row, query) =>
                      (row.itemLabel ?? '').toLowerCase().contains(query),
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
      ),
    );
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
    final isEdit = context.select((SalesInvoiceFormBloc b) => b.state.isEdit);

    return FkLookupField<Ledger>(
      label: 'Customer',
      hideLabel: hideLabel,
      // A new invoice lands focus here — the first thing a clerk fills in.
      // On an existing draft the fields are already populated, so don't grab
      // focus away from wherever the user clicks.
      autofocus: !isEdit,
      value: customer,
      enabled: !isPosting,
      displayOf: (l) {
        final code = l.code;
        return (code == null || code.isEmpty) ? l.name : '$code — ${l.name}';
      },
      loader: pagedLookup(_ledgerRepo),
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
    final tokens = context.tokens;
    final isEdit = context.select((SalesInvoiceFormBloc b) => b.state.isEdit);

    // The status badge rides in PageHeader's action slot — it's a fact about
    // the document, and this is where every other page puts page-level chrome.
    // Same draft chip the sibling detail pages already render.
    final badge = StatusChip(
      status: EntityStatus.draft,
      label: isEdit ? 'Draft' : 'New draft',
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // The in-app back button leaves via go_router (imperative), so it
            // doesn't trip the PopScope guard — confirm here too before an
            // unsaved invoice is discarded.
            final isDirty = context.read<SalesInvoiceFormBloc>().state.isDirty;
            if (isDirty) {
              final leave = await _confirmDiscardInvoice(context);
              if (!leave) return;
            }
            if (!context.mounted) return;
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(_bp.listPath);
            }
          },
        ),
        SizedBox(width: tokens.spacing.xs),
        Expanded(
          child: PageHeader(
            eyebrow: 'Sales',
            title: isEdit ? 'Edit draft invoice' : _bp.label,
            actions: [badge],
          ),
        ),
      ],
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CustomerMetricsBar(),
          SizedBox(height: tokens.spacing.md),
          const _InvoiceDetailsCard(),
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

    // Each field row is a two-column grid: FK pickers on the left (long,
    // variable labels), short metadata on the right (date, series, dropdown).
    // The grid is capped at the sum of each column's widest field, and the two
    // columns are weighted by those widths — so a column ends up exactly as
    // wide as the field in it that needs the most space, rather than a rigid
    // 50/50 split that stretches a date field to twice its content.
    final leftFlex = FieldWidths.picker.round();
    final rightFlex = FieldWidths.dropdown.round();
    final gridMaxWidth =
        FieldWidths.picker + tokens.spacing.md + FieldWidths.dropdown;

    Widget row(Widget left, Widget right) {
      return Row(
        children: [
          Expanded(flex: leftFlex, child: left),
          SizedBox(width: tokens.spacing.md),
          Expanded(flex: rightFlex, child: right),
        ],
      );
    }

    return WorkSheet(
      fill: false,
      title: 'Invoice details',
      padding: EdgeInsets.fromLTRB(
        tokens.spacing.md,
        tokens.spacing.sm,
        tokens.spacing.md,
        tokens.spacing.md,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: gridMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              row(const _GodownField(), const _VoucherDateField()),
              SizedBox(height: tokens.spacing.md),
              row(const _SalesmanField(), const _VoucherNoField()),
              SizedBox(height: tokens.spacing.md),
              row(const _ProjectField(), const _SourceTypeField()),
              SizedBox(height: tokens.spacing.md),
              row(const _PriceListField(), const SizedBox.shrink()),
              SizedBox(height: tokens.spacing.md),
              // A single FK field, held to the picker column's width rather
              // than stretched across the whole grid.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: FieldWidths.picker),
                child: const _SourceVoucherField(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceListField extends StatelessWidget {
  const _PriceListField();

  @override
  Widget build(BuildContext context) {
    final draft = context.select((SalesInvoiceFormBloc b) => b.state.draft);
    final isPosting = context.select(
      (SalesInvoiceFormBloc b) => b.state.isSubmitting,
    );
    final value = draft.priceListId == null
        ? null
        : PriceList(
            id: draft.priceListId!,
            name: draft.priceListLabel ?? '',
          );

    return FkLookupField<PriceList>(
      label: 'Price list',
      value: value,
      enabled: !isPosting,
      displayOf: (p) => p.name,
      loader: pagedLookup(_priceListRepo),
      onSelected: (p) =>
          context.read<SalesInvoiceFormBloc>().add(PriceListSelected(p)),
      helperText: 'Rates use this list when items are added',
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
      loader: searchLookup(_invoiceRepo.searchProjects),
      onSelected: (p) =>
          context.read<SalesInvoiceFormBloc>().add(ProjectSelected(p)),
    );
  }
}

class _SourceTypeField extends StatelessWidget {
  const _SourceTypeField();

  static const _types = <String>['', 'Quotation', 'SalesOrder'];

  @override
  Widget build(BuildContext context) {
    final sourceType = context.select(
      (SalesInvoiceFormBloc b) => b.state.sourceType,
    );
    final isPosting = context.select(
      (SalesInvoiceFormBloc b) => b.state.isSubmitting,
    );

    return AppDropdownField<String>(
      label: 'Convert from',
      value: _types.contains(sourceType) ? sourceType : '',
      items: _types,
      labelOf: (t) => switch (t) {
        'Quotation' => 'Quotation',
        'SalesOrder' => 'Sales order',
        _ => 'None',
      },
      enabled: !isPosting,
      onChanged: (v) =>
          context.read<SalesInvoiceFormBloc>().add(SourceTypeChanged(v ?? '')),
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
    if (sourceType.isEmpty) return const SizedBox.shrink();

    return FkLookupField<SourceVoucherLite>(
      label: 'Source $sourceType',
      value: source,
      enabled: !isPosting,
      displayOf: (s) => s.displayNo,
      loader: searchLookup(
        (q) => _invoiceRepo.searchSourceVouchers(type: sourceType, query: q),
      ),
      onSelected: (s) =>
          context.read<SalesInvoiceFormBloc>().add(SourceVoucherSelected(s)),
      helperText: 'Loads party, godown, and lines from the source document',
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
      loader: pagedLookup(_godownRepo),
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
      loader: searchLookup(_invoiceRepo.searchEmployees),
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

    final tokens = context.tokens;
    final theme = Theme.of(context);

    // Server-assigned on post; this only ever shows the series prefix, so it
    // reads as a fact rather than a field the user failed to fill in.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Voucher series',
          style: theme.textTheme.labelSmall?.copyWith(
            color: tokens.brand.inkMuted,
          ),
        ),
        SizedBox(height: tokens.spacing.xxs),
        Text(
          prefix.isEmpty ? 'Assigned on post' : prefix,
          // The document's own identity: a brass mono series once assigned;
          // muted ink while it's still a placeholder (don't stamp an absent
          // number).
          style: tokens.figures.copyWith(
            color: prefix.isEmpty ? tokens.brand.inkMuted : tokens.brand.brass,
          ),
        ),
      ],
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
    // Only the credit limit is real (it rides on the ledger). Outstanding,
    // available credit, last invoice and last payment were hardcoded demo
    // figures and are gone until a customer-balance endpoint exists — see
    // BE-014 in docs/backend-suggestions.md.
    final creditLimit = customer?.credit.creditLimit;

    // This invoice's running total, computed the same way as the Amount column
    // and the sidebar. Compared against the limit to flag a breach — but with
    // no balance endpoint (BE-014) it's this-invoice-only, never prior dues.
    final lines = context.select(
      (SalesInvoiceFormBloc b) => b.state.draft.lines,
    );
    final invoiceTotal = LineEngine.computeDocument([
      for (final line in lines)
        if (line.isComplete) line.toLineInput(),
    ]).total;
    // A zero limit means "not set" in this ledger model, not "AED 0 allowed" —
    // only flag against a real, positive limit.
    final overLimit =
        creditLimit != null &&
        creditLimit > Decimal.zero &&
        invoiceTotal > creditLimit;

    Widget metricColumn(
      String label,
      String value, {
      bool alert = false,
      Widget? note,
    }) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
                color: alert ? tokens.semanticColors.danger : tokens.brand.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (note != null) ...[SizedBox(height: tokens.spacing.xxs), note],
          ],
        ),
      );
    }

    return WorkSheet(
      fill: false,
      padding: EdgeInsets.symmetric(
        vertical: tokens.spacing.sm,
        horizontal: tokens.spacing.md,
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline, color: tokens.brand.inkMuted),
          SizedBox(width: tokens.spacing.sm),
          // A party picker doesn't get better at 860px — it just gets wider
          // than anything it will ever display.
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _CustomerField(hideLabel: true),
            ),
          ),
          if (hasCustomer && creditLimit != null) ...[
            SizedBox(width: tokens.spacing.md),
            metricColumn(
              'Credit limit',
              creditLimit.toMoney(),
              alert: overLimit,
              note: overLimit
                  ? Tooltip(
                      message:
                          'This invoice alone exceeds the limit '
                          '(excludes prior balance).',
                      child: Text(
                        'Over credit limit',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: tokens.semanticColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
