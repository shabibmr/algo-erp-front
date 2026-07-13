import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/line_engine/line_engine.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
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
import 'package:algo_erp_front/features/transactions_stock/stock_voucher_di.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Create form for stock vouchers (GT / MI / Requirement / SR).
class StockVoucherFormPage extends StatefulWidget {
  const StockVoucherFormPage({required this.kind, super.key});

  final StockVoucherKind kind;

  @override
  State<StockVoucherFormPage> createState() => _StockVoucherFormPageState();
}

class _StockVoucherFormPageState extends State<StockVoucherFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _repo = createStockVoucherRepository(
    getIt<DioClient>(),
    widget.kind,
  );
  late final _godownRepo = createGodownRepository(getIt<DioClient>());
  late final _itemRepo = createInventoryItemRepository(getIt<DioClient>());

  late StockVoucherDraft _draft;
  Godown? _fromGodown;
  Godown? _toGodown;
  Godown? _godown;
  bool _posting = false;
  String? _error;

  StockVoucherKind get kind => widget.kind;

  @override
  void initState() {
    super.initState();
    _draft = StockVoucherDraft(
      voucherPrefix: kind.blueprint.defaultPrefix ?? '',
      financialYear: DateTime.now().year.toString(),
    );
  }

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_draft.financialYear.trim().isEmpty) {
      setState(() => _error = 'Financial year is required');
      return;
    }
    if (kind.headerMode == StockHeaderMode.fromToGodown) {
      if (_draft.fromGodownId == null || _draft.toGodownId == null) {
        setState(() => _error = 'From and To godowns are required');
        return;
      }
      if (_draft.fromGodownId == _draft.toGodownId) {
        setState(() => _error = 'From and To godowns must differ');
        return;
      }
    }

    final complete = switch (kind.lineMode) {
      StockLineMode.itemQtyPrice =>
        _draft.lines.where((l) => l.isCompleteQtyPrice()).toList(),
      StockLineMode.itemCrDr =>
        _draft.lines.where((l) => l.isCompleteCrDr()).toList(),
      StockLineMode.itemRequestQty =>
        _draft.lines.where((l) => l.isCompleteRequest()).toList(),
    };
    if (complete.isEmpty) {
      setState(() => _error = 'Add at least one complete line');
      return;
    }

    setState(() {
      _posting = true;
      _error = null;
    });

    final result = await _repo.post(_draft.copyWith(lines: complete));
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() {
          _posting = false;
          _error = _messageOf(failure);
        });
      },
      (posted) {
        final totalBit = posted.total == null ? '' : ' · ${posted.total}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created ${posted.voucherNo}$totalBit')),
        );
        context.go(kind.detailRoute(posted.id));
      },
    );
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

  void _updateLine(int index, StockVoucherLine line) {
    final lines = List<StockVoucherLine>.of(_draft.lines);
    lines[index] = line;
    setState(() => _draft = _draft.copyWith(lines: lines));
  }

  Widget _godownField({
    required String label,
    required Godown? value,
    required void Function(Godown?) onSelected,
    bool required = true,
  }) {
    return FkLookupField<Godown>(
      label: label,
      value: value,
      enabled: !_posting,
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

  Widget _header() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Prefix',
                  value: _draft.voucherPrefix,
                  enabled: !_posting,
                  onChanged: (v) => setState(
                    () => _draft = _draft.copyWith(
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
                  value: _draft.financialYear,
                  enabled: !_posting,
                  onChanged: (v) => setState(
                    () => _draft = _draft.copyWith(financialYear: v),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppDateField(
            label: 'Voucher date',
            value: _draft.voucherDate,
            enabled: !_posting,
            onChanged: (d) {
              if (d != null) {
                setState(() => _draft = _draft.copyWith(voucherDate: d));
              }
            },
          ),
          if (kind.headerMode == StockHeaderMode.fromToGodown) ...[
            const SizedBox(height: 12),
            _godownField(
              label: 'From godown',
              value: _fromGodown,
              onSelected: (g) => setState(() {
                _fromGodown = g;
                _draft = _draft.copyWith(
                  fromGodownId: g?.id,
                  fromGodownLabel: g?.name,
                );
              }),
            ),
            const SizedBox(height: 12),
            _godownField(
              label: 'To godown',
              value: _toGodown,
              onSelected: (g) => setState(() {
                _toGodown = g;
                _draft = _draft.copyWith(
                  toGodownId: g?.id,
                  toGodownLabel: g?.name,
                );
              }),
            ),
          ],
          if (kind.headerMode == StockHeaderMode.optionalGodown) ...[
            const SizedBox(height: 12),
            _godownField(
              label: 'Godown',
              value: _godown,
              required: false,
              onSelected: (g) => setState(() {
                _godown = g;
                _draft = _draft.copyWith(godownId: g?.id, godownLabel: g?.name);
              }),
            ),
          ],
          if (kind.supportsRequirementRef) ...[
            const SizedBox(height: 12),
            AppTextField(
              label: 'Requirement voucher no',
              value: _draft.requirementVoucherNo,
              enabled: !_posting,
              helperText: 'Optional link to a Requirement voucher_no',
              onChanged: (v) => setState(
                () => _draft = _draft.copyWith(
                  requirementVoucherNo: v.isEmpty ? null : v,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          AppTextField(
            label: 'Narration',
            value: _draft.narration,
            enabled: !_posting,
            onChanged: (v) => setState(
              () => _draft = _draft.copyWith(narration: v.isEmpty ? null : v),
            ),
          ),
        ],
      ),
    );
  }

  LineItemColumn<StockVoucherLine> get _itemCol => LineItemColumn(
    label: 'Item',
    flex: 3,
    cellBuilder: (context, row, i) => FkLookupField<InventoryItem>(
      label: 'Item',
      value: row.itemId == null ? null : _stubItem(row),
      enabled: !_posting,
      displayOf: (item) =>
          item.code.isEmpty ? item.name : '${item.code} — ${item.name}',
      loader: (q) async {
        final r = await _itemRepo.list(PageQuery(search: q));
        return r.fold((_) => const [], (p) => p.items);
      },
      onSelected: (item) {
        if (item == null) {
          _updateLine(i, row.copyWith(itemId: null, itemLabel: null));
          return;
        }
        _updateLine(
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

  List<LineItemColumn<StockVoucherLine>> get _columns {
    switch (kind.lineMode) {
      case StockLineMode.itemQtyPrice:
        return [
          _itemCol,
          LineItemColumn(
            label: 'Qty',
            cellBuilder: (context, row, i) => AppDecimalField(
              label: 'Qty',
              value: row.quantity,
              enabled: !_posting,
              onChanged: (v) =>
                  _updateLine(i, row.copyWith(quantity: v ?? Decimal.one)),
            ),
          ),
          LineItemColumn(
            label: 'Price',
            cellBuilder: (context, row, i) => AppDecimalField(
              label: 'Price',
              value: row.price,
              enabled: !_posting,
              onChanged: (v) =>
                  _updateLine(i, row.copyWith(price: v ?? Decimal.zero)),
            ),
          ),
          if (kind.supportsAdjValue)
            LineItemColumn(
              label: 'Adj',
              cellBuilder: (context, row, i) => AppDecimalField(
                label: 'Adj value',
                value: row.adjValue,
                enabled: !_posting,
                onChanged: (v) =>
                    _updateLine(i, row.copyWith(adjValue: v ?? Decimal.zero)),
              ),
            ),
          LineItemColumn(
            label: 'Narration',
            flex: 2,
            cellBuilder: (context, row, i) => AppTextField(
              label: 'Narration',
              value: row.narration,
              enabled: !_posting,
              onChanged: (v) =>
                  _updateLine(i, row.copyWith(narration: v.isEmpty ? null : v)),
            ),
          ),
        ];
      case StockLineMode.itemCrDr:
        return [
          _itemCol,
          LineItemColumn(
            label: 'Cr qty',
            cellBuilder: (context, row, i) => AppDecimalField(
              label: 'Cr qty',
              value: row.crQty,
              enabled: !_posting,
              onChanged: (v) =>
                  _updateLine(i, row.copyWith(crQty: v ?? Decimal.zero)),
            ),
          ),
          LineItemColumn(
            label: 'Dr qty',
            cellBuilder: (context, row, i) => AppDecimalField(
              label: 'Dr qty',
              value: row.drQty,
              enabled: !_posting,
              onChanged: (v) =>
                  _updateLine(i, row.copyWith(drQty: v ?? Decimal.zero)),
            ),
          ),
          LineItemColumn(
            label: 'Price',
            cellBuilder: (context, row, i) => AppDecimalField(
              label: 'Price',
              value: row.price,
              enabled: !_posting,
              onChanged: (v) =>
                  _updateLine(i, row.copyWith(price: v ?? Decimal.zero)),
            ),
          ),
          LineItemColumn(
            label: 'Narration',
            flex: 2,
            cellBuilder: (context, row, i) => AppTextField(
              label: 'Narration',
              value: row.narration,
              enabled: !_posting,
              onChanged: (v) =>
                  _updateLine(i, row.copyWith(narration: v.isEmpty ? null : v)),
            ),
          ),
        ];
      case StockLineMode.itemRequestQty:
        return [
          _itemCol,
          LineItemColumn(
            label: 'Request qty',
            cellBuilder: (context, row, i) => AppDecimalField(
              label: 'Request qty',
              value: row.requestQty,
              enabled: !_posting,
              onChanged: (v) =>
                  _updateLine(i, row.copyWith(requestQty: v ?? Decimal.one)),
            ),
          ),
          LineItemColumn(
            label: 'Remarks',
            flex: 2,
            cellBuilder: (context, row, i) => AppTextField(
              label: 'Remarks',
              value: row.narration,
              enabled: !_posting,
              onChanged: (v) =>
                  _updateLine(i, row.copyWith(narration: v.isEmpty ? null : v)),
            ),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bp = kind.blueprint;
    final tokens = context.tokens;
    // DocumentSurface fits qty×price; request-qty totals as qty×0 price.
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
              header: _header(),
              rows: _draft.lines,
              columns: _columns,
              onRowsChanged: (rows) =>
                  setState(() => _draft = _draft.copyWith(lines: rows)),
              newRow: StockVoucherLine.new,
              lineInputsOf: _lineInput,
              onPost: _submit,
              postLabel: kind.createLabel,
              posting: _posting,
              enabled: !_posting,
              errorText: _error,
              totalsLabel: kind.lineMode == StockLineMode.itemRequestQty
                  ? 'Requested qty total'
                  : 'Totals',
            ),
          ),
        ],
      ),
    );
  }
}
