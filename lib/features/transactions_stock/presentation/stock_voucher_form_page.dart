import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/line_engine/line_engine.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/document_surface.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_kind.dart';
import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_models.dart';
import 'package:algo_erp_front/core/widgets/data_display/line_item_grid.dart';
import 'package:algo_erp_front/core/widgets/fields/app_date_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_decimal_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:algo_erp_front/features/inventory_godown/godown_di.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:algo_erp_front/features/inventory_item/inventory_item_di.dart';
import 'package:algo_erp_front/features/transactions_stock/cubit/stock_voucher_form_cubit.dart';
import 'package:algo_erp_front/features/transactions_stock/stock_voucher_di.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Create form for stock vouchers (GT / MI / Requirement / SR).
class StockVoucherFormPage extends StatelessWidget {
  const StockVoucherFormPage({required this.kind, super.key});

  final StockVoucherKind kind;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StockVoucherFormCubit(
        kind: kind,
        repository: createStockVoucherRepository(getIt<DioClient>(), kind),
      ),
      child: _StockVoucherFormView(kind: kind),
    );
  }
}

class _StockVoucherFormView extends StatefulWidget {
  const _StockVoucherFormView({required this.kind});

  final StockVoucherKind kind;

  @override
  State<_StockVoucherFormView> createState() => _StockVoucherFormViewState();
}

class _StockVoucherFormViewState extends State<_StockVoucherFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _godownRepo = createGodownRepository(getIt<DioClient>());
  late final _itemRepo = createInventoryItemRepository(getIt<DioClient>());

  StockVoucherKind get kind => widget.kind;

  InventoryItem _stubItem(StockVoucherLine row) => InventoryItem(
    id: row.itemId!,
    name: row.itemLabel ?? '',
    code: '',
    price: row.price,
    basePrice: Decimal.zero,
    standardCost: Decimal.zero,
    vatRate: Decimal.zero,
    openingStock: Decimal.zero,
    reorderLevel: Decimal.zero,
  );

  LineInput? _lineInput(StockVoucherLine row) {
    switch (kind.lineMode) {
      case StockLineMode.itemQtyPrice:
        if (!row.isCompleteQtyPrice()) return null;
        return LineInput(quantity: row.quantity, price: row.price);
      case StockLineMode.itemCrDr:
        if (!row.isCompleteCrDr()) return null;
        final qty = row.crQty > Decimal.zero ? row.crQty : row.drQty;
        return LineInput(quantity: qty, price: row.price);
      case StockLineMode.itemRequestQty:
        if (!row.isCompleteRequest()) return null;
        return LineInput(quantity: row.requestQty, price: Decimal.zero);
    }
  }

  Widget _godownField({
    required String label,
    required Godown? value,
    required void Function(Godown?) onSelected,
    required bool posting,
    bool required = true,
  }) {
    return FkLookupField<Godown>(
      label: label,
      value: value,
      enabled: !posting,
      displayOf: (g) => g.name,
      loader: (q) async {
        final r = await _godownRepo.list(PageQuery(search: q));
        return r.fold((_) => const [], (p) => p.items);
      },
      onSelected: onSelected,
      validator: required
          ? (v) => v == null ? '$label is required' : null
          : null,
    );
  }

  Widget _header(StockVoucherFormCubit cubit, StockVoucherFormState state) {
    final draft = state.draft;
    final posting = state.posting;
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Prefix',
                  value: draft.voucherPrefix,
                  enabled: !posting,
                  onChanged: (v) => cubit.updateDraft(
                    draft.copyWith(
                      voucherPrefix: v.isEmpty
                          ? (kind.blueprint.defaultPrefix ?? '')
                          : v,
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'Financial year',
                  value: draft.financialYear,
                  enabled: !posting,
                  onChanged: (v) =>
                      cubit.updateDraft(draft.copyWith(financialYear: v)),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppDateField(
            label: 'Voucher date',
            value: draft.voucherDate,
            enabled: !posting,
            onChanged: (d) {
              if (d != null) {
                cubit.updateDraft(draft.copyWith(voucherDate: d));
              }
            },
          ),
          if (kind.headerMode == StockHeaderMode.fromToGodown) ...[
            const SizedBox(height: 12),
            _godownField(
              label: 'From godown',
              value: state.fromGodown,
              posting: posting,
              onSelected: cubit.setFromGodown,
            ),
            const SizedBox(height: 12),
            _godownField(
              label: 'To godown',
              value: state.toGodown,
              posting: posting,
              onSelected: cubit.setToGodown,
            ),
          ],
          if (kind.headerMode == StockHeaderMode.optionalGodown) ...[
            const SizedBox(height: 12),
            _godownField(
              label: 'Godown',
              value: state.godown,
              required: false,
              posting: posting,
              onSelected: cubit.setGodown,
            ),
          ],
          if (kind.supportsRequirementRef) ...[
            const SizedBox(height: 12),
            AppTextField(
              label: 'Requirement voucher no',
              value: draft.requirementVoucherNo,
              enabled: !posting,
              helperText: 'Optional link to a Requirement voucher_no',
              onChanged: (v) => cubit.updateDraft(
                draft.copyWith(requirementVoucherNo: v.isEmpty ? null : v),
              ),
            ),
          ],
          const SizedBox(height: 12),
          AppTextField(
            label: 'Narration',
            value: draft.narration,
            enabled: !posting,
            onChanged: (v) => cubit.updateDraft(
              draft.copyWith(narration: v.isEmpty ? null : v),
            ),
          ),
        ],
      ),
    );
  }

  LineItemColumn<StockVoucherLine> _itemCol(
    StockVoucherFormCubit cubit,
    bool posting,
  ) => LineItemColumn(
    label: 'Item',
    flex: 3,
    cellBuilder: (context, row, i) => FkLookupField<InventoryItem>(
      label: 'Item',
      value: row.itemId == null ? null : _stubItem(row),
      enabled: !posting,
      displayOf: (item) =>
          item.code.isEmpty ? item.name : '${item.code} — ${item.name}',
      loader: (q) async {
        final r = await _itemRepo.list(PageQuery(search: q));
        return r.fold((_) => const [], (p) => p.items);
      },
      onSelected: (item) {
        if (item == null) {
          cubit.updateLine(i, row.copyWith(itemId: null, itemLabel: null));
          return;
        }
        cubit.updateLine(
          i,
          row.copyWith(
            itemId: item.id,
            itemLabel: item.name,
            price: item.price,
          ),
        );
      },
    ),
  );

  List<LineItemColumn<StockVoucherLine>> _columns(
    StockVoucherFormCubit cubit,
    StockVoucherFormState state,
  ) {
    final posting = state.posting;
    switch (kind.lineMode) {
      case StockLineMode.itemQtyPrice:
        return [
          _itemCol(cubit, posting),
          LineItemColumn(
            label: 'Qty',
            cellBuilder: (context, row, i) => AppDecimalField(
              label: 'Qty',
              value: row.quantity,
              enabled: !posting,
              onChanged: (v) =>
                  cubit.updateLine(i, row.copyWith(quantity: v ?? Decimal.one)),
            ),
          ),
          LineItemColumn(
            label: 'Price',
            cellBuilder: (context, row, i) => AppDecimalField(
              label: 'Price',
              value: row.price,
              enabled: !posting,
              onChanged: (v) =>
                  cubit.updateLine(i, row.copyWith(price: v ?? Decimal.zero)),
            ),
          ),
          if (kind.supportsAdjValue)
            LineItemColumn(
              label: 'Adj',
              cellBuilder: (context, row, i) => AppDecimalField(
                label: 'Adj value',
                value: row.adjValue,
                enabled: !posting,
                onChanged: (v) => cubit.updateLine(
                  i,
                  row.copyWith(adjValue: v ?? Decimal.zero),
                ),
              ),
            ),
          LineItemColumn(
            label: 'Narration',
            flex: 2,
            cellBuilder: (context, row, i) => AppTextField(
              label: 'Narration',
              value: row.narration,
              enabled: !posting,
              onChanged: (v) => cubit.updateLine(
                i,
                row.copyWith(narration: v.isEmpty ? null : v),
              ),
            ),
          ),
        ];
      case StockLineMode.itemCrDr:
        return [
          _itemCol(cubit, posting),
          LineItemColumn(
            label: 'Cr qty',
            cellBuilder: (context, row, i) => AppDecimalField(
              label: 'Cr qty',
              value: row.crQty,
              enabled: !posting,
              onChanged: (v) =>
                  cubit.updateLine(i, row.copyWith(crQty: v ?? Decimal.zero)),
            ),
          ),
          LineItemColumn(
            label: 'Dr qty',
            cellBuilder: (context, row, i) => AppDecimalField(
              label: 'Dr qty',
              value: row.drQty,
              enabled: !posting,
              onChanged: (v) =>
                  cubit.updateLine(i, row.copyWith(drQty: v ?? Decimal.zero)),
            ),
          ),
          LineItemColumn(
            label: 'Price',
            cellBuilder: (context, row, i) => AppDecimalField(
              label: 'Price',
              value: row.price,
              enabled: !posting,
              onChanged: (v) =>
                  cubit.updateLine(i, row.copyWith(price: v ?? Decimal.zero)),
            ),
          ),
          LineItemColumn(
            label: 'Narration',
            flex: 2,
            cellBuilder: (context, row, i) => AppTextField(
              label: 'Narration',
              value: row.narration,
              enabled: !posting,
              onChanged: (v) => cubit.updateLine(
                i,
                row.copyWith(narration: v.isEmpty ? null : v),
              ),
            ),
          ),
        ];
      case StockLineMode.itemRequestQty:
        return [
          _itemCol(cubit, posting),
          LineItemColumn(
            label: 'Request qty',
            cellBuilder: (context, row, i) => AppDecimalField(
              label: 'Request qty',
              value: row.requestQty,
              enabled: !posting,
              onChanged: (v) => cubit.updateLine(
                i,
                row.copyWith(requestQty: v ?? Decimal.one),
              ),
            ),
          ),
          LineItemColumn(
            label: 'Remarks',
            flex: 2,
            cellBuilder: (context, row, i) => AppTextField(
              label: 'Remarks',
              value: row.narration,
              enabled: !posting,
              onChanged: (v) => cubit.updateLine(
                i,
                row.copyWith(narration: v.isEmpty ? null : v),
              ),
            ),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bp = kind.blueprint;
    final tokens = context.tokens;
    return BlocListener<StockVoucherFormCubit, StockVoucherFormState>(
      listenWhen: (p, c) => p.posted != c.posted && c.posted != null,
      listener: (context, state) {
        final posted = state.posted!;
        final totalBit = posted.total == null ? '' : ' · ${posted.total}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created ${posted.voucherNo}$totalBit')),
        );
        context.go(kind.detailRoute(posted.id));
      },
      child: BlocBuilder<StockVoucherFormCubit, StockVoucherFormState>(
        builder: (context, state) {
          final cubit = context.read<StockVoucherFormCubit>();
          return AdaptiveLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New ${bp.label}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: tokens.spacing.md),
                Expanded(
                  child: DocumentSurface<StockVoucherLine>(
                    blueprint: bp,
                    header: _header(cubit, state),
                    rows: state.draft.lines,
                    columns: _columns(cubit, state),
                    onRowsChanged: cubit.setLines,
                    newRow: StockVoucherLine.new,
                    lineInputsOf: _lineInput,
                    onPost: () => cubit.submit(
                      formIsValid: () =>
                          _formKey.currentState?.validate() ?? false,
                    ),
                    postLabel: kind.createLabel,
                    posting: state.posting,
                    enabled: !state.posting,
                    errorText: state.error,
                    totalsLabel: kind.lineMode == StockLineMode.itemRequestQty
                        ? 'Requested qty total'
                        : 'Totals',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
