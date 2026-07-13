import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/line_engine/line_engine.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/document_surface.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_kind.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_models.dart';
import 'package:algo_erp_front/core/widgets/data_display/line_item_grid.dart';
import 'package:algo_erp_front/core/widgets/fields/app_date_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_decimal_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_number_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:algo_erp_front/features/inventory_godown/godown_di.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:algo_erp_front/features/inventory_item/inventory_item_di.dart';
import 'package:algo_erp_front/features/transactions_item_qty/item_qty_di.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Create form for an [ItemQtyVoucherKind] via DocumentSurface + LineEngine.
class ItemQtyFormPage extends StatefulWidget {
  const ItemQtyFormPage({required this.kind, super.key});

  final ItemQtyVoucherKind kind;

  @override
  State<ItemQtyFormPage> createState() => _ItemQtyFormPageState();
}

class _ItemQtyFormPageState extends State<ItemQtyFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _repo = createItemQtyRepository(getIt<DioClient>(), widget.kind);
  late final _ledgerRepo = createLedgerRepository(getIt<DioClient>());
  late final _godownRepo = createGodownRepository(getIt<DioClient>());
  late final _itemRepo = createInventoryItemRepository(getIt<DioClient>());

  late ItemQtyDraft _draft;
  Ledger? _party;
  Godown? _godown;
  ItemQtySourceLite? _source;
  bool _posting = false;
  String? _error;

  ItemQtyVoucherKind get kind => widget.kind;

  @override
  void initState() {
    super.initState();
    _draft = ItemQtyDraft(
      voucherPrefix: kind.blueprint.defaultPrefix ?? '',
      financialYear: DateTime.now().year.toString(),
    );
  }

  LineInput? _lineInput(ItemQtyLine row) {
    if (!row.isComplete) return null;
    return LineInput(
      quantity: row.quantity,
      price: row.price,
      discountPercent: row.discountPercent,
      taxRate: row.taxRate,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_draft.partyLedgerId == null) {
      setState(() => _error = '${kind.partyLabel} is required');
      return;
    }
    if (kind.requiresGodown && _draft.godownId == null) {
      setState(() => _error = 'Godown is required');
      return;
    }
    final complete = _draft.lines.where((l) => l.isComplete).toList();
    if (complete.isEmpty) {
      setState(
        () => _error = 'Add at least one complete line (item, qty, price)',
      );
      return;
    }
    if (_draft.financialYear.trim().isEmpty) {
      setState(() => _error = 'Financial year is required');
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created ${posted.voucherNo} · ${posted.total}'),
          ),
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

  void _updateLine(int index, ItemQtyLine line) {
    final lines = List<ItemQtyLine>.of(_draft.lines);
    lines[index] = line;
    setState(() => _draft = _draft.copyWith(lines: lines));
  }

  InventoryItem _stubItem(ItemQtyLine row) => InventoryItem(
    id: row.itemId!,
    name: row.itemLabel ?? '',
    code: '',
    price: row.price,
    basePrice: Decimal.zero,
    standardCost: Decimal.zero,
    vatRate: row.taxRate,
    openingStock: Decimal.zero,
    reorderLevel: Decimal.zero,
  );

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
          const SizedBox(height: 12),
          FkLookupField<Ledger>(
            label: kind.partyLabel,
            value: _party,
            enabled: !_posting,
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
            onSelected: (l) => setState(() {
              _party = l;
              _draft = _draft.copyWith(
                partyLedgerId: l?.id,
                partyLabel: l?.name,
                billingName: l?.name,
              );
            }),
            validator: (v) =>
                v == null ? '${kind.partyLabel} is required' : null,
          ),
          if (kind.requiresGodown) ...[
            const SizedBox(height: 12),
            FkLookupField<Godown>(
              label: 'Godown',
              value: _godown,
              enabled: !_posting,
              displayOf: (g) => g.name,
              loader: (q) async {
                final r = await _godownRepo.list(PageQuery(search: q));
                return r.fold((_) => const [], (p) => p.items);
              },
              onSelected: (g) => setState(() {
                _godown = g;
                _draft = _draft.copyWith(godownId: g?.id, godownLabel: g?.name);
              }),
              validator: (v) => v == null ? 'Godown is required' : null,
            ),
          ],
          if (kind.supportsSource) ...[
            const SizedBox(height: 12),
            FkLookupField<ItemQtySourceLite>(
              label: 'Convert from ${kind.sourceLifecycleType}',
              value: _source,
              enabled: !_posting,
              helperText: 'Optional — loads party, godown, and lines',
              displayOf: (s) => '${s.type} ${s.displayNo}',
              loader: (q) async {
                final r = await _repo.searchSourceVouchers(query: q);
                return r.fold((_) => const [], (list) => list);
              },
              onSelected: (s) async {
                if (s == null) {
                  setState(() {
                    _source = null;
                    _draft = _draft.copyWith(
                      sourceVoucherId: null,
                      sourceVoucherLabel: null,
                    );
                  });
                  return;
                }
                final full = await _repo.getSourceVoucher(s.id);
                if (!mounted) return;
                full.fold((f) => setState(() => _error = _messageOf(f)), (src) {
                  setState(() {
                    _source = src;
                    _draft = _draft.copyWith(
                      sourceVoucherId: src.id,
                      sourceVoucherLabel: src.displayNo,
                      partyLedgerId: src.partyLedgerId,
                      billingName: src.billingName,
                      godownId: src.godownId ?? _draft.godownId,
                      lines: src.lines,
                    );
                    if (src.partyLedgerId != null) {
                      _party = Ledger(
                        id: src.partyLedgerId!,
                        name: src.billingName ?? 'Ledger #${src.partyLedgerId}',
                        openingBalance: Decimal.zero,
                      );
                    }
                    if (src.godownId != null) {
                      _godown = Godown(
                        id: src.godownId!,
                        name: 'Godown #${src.godownId}',
                      );
                      _godownRepo.getById(src.godownId!).then((r) {
                        r.fold((_) {}, (g) {
                          if (mounted) {
                            setState(() {
                              _godown = g;
                              _draft = _draft.copyWith(godownLabel: g.name);
                            });
                          }
                        });
                      });
                    }
                  });
                });
              },
            ),
          ],
          const SizedBox(height: 12),
          AppTextField(
            label: 'Billing name',
            value: _draft.billingName,
            enabled: !_posting,
            onChanged: (v) => setState(
              () => _draft = _draft.copyWith(billingName: v.isEmpty ? null : v),
            ),
          ),
          if (kind.supportsCreditDays) ...[
            const SizedBox(height: 12),
            AppNumberField(
              label: 'Credit days',
              value: _draft.creditDays,
              enabled: !_posting,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(creditDays: v ?? 30)),
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

  List<LineItemColumn<ItemQtyLine>> get _columns => [
    LineItemColumn(
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
              taxRate: item.vatRate,
            ),
          );
        },
      ),
    ),
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
    LineItemColumn(
      label: 'Disc %',
      cellBuilder: (context, row, i) => AppDecimalField(
        label: 'Disc %',
        value: row.discountPercent,
        enabled: !_posting,
        onChanged: (v) =>
            _updateLine(i, row.copyWith(discountPercent: v ?? Decimal.zero)),
      ),
    ),
    LineItemColumn(
      label: 'Tax %',
      cellBuilder: (context, row, i) => AppDecimalField(
        label: 'Tax %',
        value: row.taxRate,
        enabled: !_posting,
        onChanged: (v) =>
            _updateLine(i, row.copyWith(taxRate: v ?? Decimal.zero)),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bp = kind.blueprint;
    return AdaptiveLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New ${bp.label}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: DocumentSurface<ItemQtyLine>(
              blueprint: bp,
              header: _header(),
              rows: _draft.lines,
              columns: _columns,
              onRowsChanged: (rows) =>
                  setState(() => _draft = _draft.copyWith(lines: rows)),
              newRow: ItemQtyLine.new,
              lineInputsOf: _lineInput,
              onPost: _submit,
              postLabel: kind.createLabel,
              posting: _posting,
              enabled: !_posting,
              errorText: _error,
            ),
          ),
        ],
      ),
    );
  }
}
