import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/line_engine/line_engine.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/document_surface.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_kind.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_models.dart';
import 'package:algo_erp_front/core/widgets/data_display/line_item_grid.dart';
import 'package:algo_erp_front/core/widgets/fields/app_date_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_decimal_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/transactions_ledger_amount/ledger_amount_di.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Create form for Payment / Receipt via DocumentSurface.
///
/// Totals use LineEngine with qty=1 × amount so the shared surface works
/// without a second math engine.
class LedgerAmountFormPage extends StatefulWidget {
  const LedgerAmountFormPage({required this.kind, super.key});

  final LedgerAmountVoucherKind kind;

  @override
  State<LedgerAmountFormPage> createState() => _LedgerAmountFormPageState();
}

class _LedgerAmountFormPageState extends State<LedgerAmountFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _repo = createLedgerAmountRepository(
    getIt<DioClient>(),
    widget.kind,
  );
  late final _ledgerRepo = createLedgerRepository(getIt<DioClient>());

  late LedgerAmountDraft _draft;
  Ledger? _cashBank;
  bool _posting = false;
  String? _error;

  LedgerAmountVoucherKind get kind => widget.kind;

  @override
  void initState() {
    super.initState();
    _draft = LedgerAmountDraft(
      voucherPrefix: kind.blueprint.defaultPrefix ?? '',
      financialYear: DateTime.now().year.toString(),
    );
  }

  String _ledgerLabel(Ledger l) {
    final code = l.code;
    return (code == null || code.isEmpty) ? l.name : '$code — ${l.name}';
  }

  LineInput? _lineInput(LedgerAmountLine row) {
    if (!row.isComplete) return null;
    return LineInput(quantity: Decimal.one, price: row.amount);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_draft.cashBankLedgerId == null) {
      setState(() => _error = 'Cash/Bank ledger is required');
      return;
    }
    final complete = _draft.lines.where((l) => l.isComplete).toList();
    if (complete.isEmpty) {
      setState(
        () => _error = 'Add at least one complete line (ledger, amount)',
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
            content: Text('Posted ${posted.voucherNo} · ${posted.total}'),
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

  void _updateLine(int index, LedgerAmountLine line) {
    final lines = List<LedgerAmountLine>.of(_draft.lines);
    lines[index] = line;
    setState(() => _draft = _draft.copyWith(lines: lines));
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
          const SizedBox(height: 12),
          FkLookupField<Ledger>(
            label: 'Cash / Bank ledger',
            value: _cashBank,
            enabled: !_posting,
            helperText:
                'Source of funds (payment) or deposit account (receipt)',
            displayOf: _ledgerLabel,
            loader: (q) async {
              final r = await _ledgerRepo.list(PageQuery(search: q));
              return r.fold((_) => const [], (p) => p.items);
            },
            onSelected: (l) => setState(() {
              _cashBank = l;
              _draft = _draft.copyWith(
                cashBankLedgerId: l?.id,
                cashBankLabel: l == null ? null : _ledgerLabel(l),
              );
            }),
            validator: (v) => v == null ? 'Cash/Bank is required' : null,
          ),
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

  List<LineItemColumn<LedgerAmountLine>> get _columns => [
    LineItemColumn(
      label: 'Ledger',
      flex: 3,
      cellBuilder: (context, row, i) => FkLookupField<Ledger>(
        label: 'Ledger',
        value: row.ledgerId == null
            ? null
            : Ledger(
                id: row.ledgerId!,
                name: row.ledgerLabel ?? 'Ledger #${row.ledgerId}',
                openingBalance: Decimal.zero,
              ),
        enabled: !_posting,
        displayOf: _ledgerLabel,
        loader: (q) async {
          final r = await _ledgerRepo.list(PageQuery(search: q));
          return r.fold((_) => const [], (p) => p.items);
        },
        onSelected: (l) {
          if (l == null) {
            _updateLine(i, row.copyWith(ledgerId: null, ledgerLabel: null));
            return;
          }
          _updateLine(
            i,
            row.copyWith(ledgerId: l.id, ledgerLabel: _ledgerLabel(l)),
          );
        },
      ),
    ),
    LineItemColumn(
      label: 'Amount',
      cellBuilder: (context, row, i) => AppDecimalField(
        label: 'Amount',
        value: row.amount,
        enabled: !_posting,
        onChanged: (v) =>
            _updateLine(i, row.copyWith(amount: v ?? Decimal.zero)),
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
            child: DocumentSurface<LedgerAmountLine>(
              blueprint: bp,
              header: _header(),
              rows: _draft.lines,
              columns: _columns,
              onRowsChanged: (rows) =>
                  setState(() => _draft = _draft.copyWith(lines: rows)),
              newRow: LedgerAmountLine.new,
              lineInputsOf: _lineInput,
              onPost: _submit,
              postLabel: kind.createLabel,
              posting: _posting,
              enabled: !_posting,
              errorText: _error,
              totalsLabel: 'Total',
            ),
          ),
        ],
      ),
    );
  }
}
