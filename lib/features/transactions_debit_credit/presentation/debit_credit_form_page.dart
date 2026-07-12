import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_dto.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_kind.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_models.dart';
import 'package:algo_erp_front/core/widgets/data_display/line_item_grid.dart';
import 'package:algo_erp_front/core/widgets/fields/app_date_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_decimal_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/transactions_debit_credit/debit_credit_di.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Create form for Journal / Contra with client-side DR/CR balance check.
class DebitCreditFormPage extends StatefulWidget {
  const DebitCreditFormPage({required this.kind, super.key});

  final DebitCreditVoucherKind kind;

  @override
  State<DebitCreditFormPage> createState() => _DebitCreditFormPageState();
}

class _DebitCreditFormPageState extends State<DebitCreditFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _repo = createDebitCreditRepository(
    getIt<DioClient>(),
    widget.kind,
  );
  late final _ledgerRepo = createLedgerRepository(getIt<DioClient>());

  late DebitCreditDraft _draft;
  bool _posting = false;
  String? _error;

  DebitCreditVoucherKind get kind => widget.kind;
  bool get _isJournal => kind.lineMode == DebitCreditLineMode.dualAmount;

  @override
  void initState() {
    super.initState();
    _draft = DebitCreditDraft(
      voucherPrefix: kind.blueprint.defaultPrefix ?? '',
      financialYear: DateTime.now().year.toString(),
    );
  }

  String _ledgerLabel(Ledger l) {
    final code = l.code;
    return (code == null || code.isEmpty) ? l.name : '$code — ${l.name}';
  }

  ({Decimal debit, Decimal credit}) get _totals =>
      DebitCreditDto.totals(_draft, mode: kind.lineMode);

  bool get _balanced {
    final t = _totals;
    return t.debit > Decimal.zero && t.debit == t.credit;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_draft.financialYear.trim().isEmpty) {
      setState(() => _error = 'Financial year is required');
      return;
    }

    final complete = _isJournal
        ? _draft.lines.where((l) => l.isCompleteForJournal()).toList()
        : _draft.lines.where((l) => l.isCompleteForContra()).toList();
    if (complete.length < kind.minLines) {
      setState(
        () => _error =
            'Add at least ${kind.minLines} complete lines (ledger + amount)',
      );
      return;
    }
    if (!_balanced) {
      final t = _totals;
      setState(
        () => _error = 'Debits (${t.debit}) must equal credits (${t.credit})',
      );
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

  void _updateLine(int index, DebitCreditLine line) {
    final lines = List<DebitCreditLine>.of(_draft.lines);
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
                  initialValue: _draft.voucherPrefix,
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
                  initialValue: _draft.financialYear,
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
          AppTextField(
            label: 'Narration',
            initialValue: _draft.narration,
            enabled: !_posting,
            onChanged: (v) => setState(
              () => _draft = _draft.copyWith(narration: v.isEmpty ? null : v),
            ),
          ),
        ],
      ),
    );
  }

  List<LineItemColumn<DebitCreditLine>> get _columns {
    final ledgerCol = LineItemColumn<DebitCreditLine>(
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
    );

    if (_isJournal) {
      return [
        ledgerCol,
        LineItemColumn(
          label: 'Debit',
          cellBuilder: (context, row, i) => AppDecimalField(
            label: 'Debit',
            initialValue: row.debit,
            enabled: !_posting,
            onChanged: (v) =>
                _updateLine(i, row.copyWith(debit: v ?? Decimal.zero)),
          ),
        ),
        LineItemColumn(
          label: 'Credit',
          cellBuilder: (context, row, i) => AppDecimalField(
            label: 'Credit',
            initialValue: row.credit,
            enabled: !_posting,
            onChanged: (v) =>
                _updateLine(i, row.copyWith(credit: v ?? Decimal.zero)),
          ),
        ),
        LineItemColumn(
          label: 'Narration',
          flex: 2,
          cellBuilder: (context, row, i) => AppTextField(
            label: 'Narration',
            initialValue: row.narration,
            enabled: !_posting,
            onChanged: (v) =>
                _updateLine(i, row.copyWith(narration: v.isEmpty ? null : v)),
          ),
        ),
      ];
    }

    return [
      ledgerCol,
      LineItemColumn(
        label: 'Side',
        cellBuilder: (context, row, i) =>
            DropdownButtonFormField<DebitCreditSide>(
              initialValue: row.side,
              decoration: const InputDecoration(labelText: 'Side'),
              items: const [
                DropdownMenuItem(
                  value: DebitCreditSide.debit,
                  child: Text('DR'),
                ),
                DropdownMenuItem(
                  value: DebitCreditSide.credit,
                  child: Text('CR'),
                ),
              ],
              onChanged: _posting
                  ? null
                  : (v) {
                      if (v != null) _updateLine(i, row.copyWith(side: v));
                    },
            ),
      ),
      LineItemColumn(
        label: 'Amount',
        cellBuilder: (context, row, i) => AppDecimalField(
          label: 'Amount',
          initialValue: row.amount,
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
          initialValue: row.narration,
          enabled: !_posting,
          onChanged: (v) =>
              _updateLine(i, row.copyWith(narration: v.isEmpty ? null : v)),
        ),
      ),
    ];
  }

  Widget _balanceBar(BuildContext context) {
    final tokens = context.tokens;
    final t = _totals;
    final balanced = _balanced;
    final color = balanced
        ? tokens.semanticColors.success
        : tokens.semanticColors.danger;
    return Container(
      padding: EdgeInsets.all(tokens.spacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(tokens.radii.sm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Debit: ${t.debit}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Expanded(
            child: Text(
              'Credit: ${t.credit}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Text(
            balanced ? 'Balanced' : 'Out of balance',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bp = kind.blueprint;
    final tokens = context.tokens;
    return AdaptiveLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'New ${bp.label}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: tokens.spacing.md),
          if (_error != null) ...[
            Container(
              padding: EdgeInsets.all(tokens.spacing.sm),
              decoration: BoxDecoration(
                color: tokens.semanticColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(tokens.radii.sm),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: tokens.semanticColors.danger),
              ),
            ),
            SizedBox(height: tokens.spacing.md),
          ],
          _header(),
          SizedBox(height: tokens.spacing.md),
          Text('Lines', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: tokens.spacing.sm),
          Expanded(
            child: SingleChildScrollView(
              child: LineItemGrid<DebitCreditLine>(
                rows: _draft.lines,
                columns: _columns,
                onChanged: (rows) =>
                    setState(() => _draft = _draft.copyWith(lines: rows)),
                newRow: _posting ? null : DebitCreditLine.new,
                enabled: !_posting,
              ),
            ),
          ),
          SizedBox(height: tokens.spacing.md),
          _balanceBar(context),
          SizedBox(height: tokens.spacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: PermissionGate(
              module: bp.rbacModule,
              action: PermissionAction.create,
              child: FilledButton(
                onPressed: _posting ? null : _submit,
                child: _posting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(kind.createLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
