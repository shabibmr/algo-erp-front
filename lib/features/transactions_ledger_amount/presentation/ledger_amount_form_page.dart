import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/line_engine/line_engine.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
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
import 'package:algo_erp_front/features/transactions_ledger_amount/cubit/ledger_amount_form_cubit.dart';
import 'package:algo_erp_front/features/transactions_ledger_amount/ledger_amount_di.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Create form for Payment / Receipt via DocumentSurface.
class LedgerAmountFormPage extends StatelessWidget {
  const LedgerAmountFormPage({required this.kind, super.key});

  final LedgerAmountVoucherKind kind;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LedgerAmountFormCubit(
        kind: kind,
        repository: createLedgerAmountRepository(getIt<DioClient>(), kind),
      ),
      child: _LedgerAmountFormView(kind: kind),
    );
  }
}

class _LedgerAmountFormView extends StatefulWidget {
  const _LedgerAmountFormView({required this.kind});

  final LedgerAmountVoucherKind kind;

  @override
  State<_LedgerAmountFormView> createState() => _LedgerAmountFormViewState();
}

class _LedgerAmountFormViewState extends State<_LedgerAmountFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _ledgerRepo = createLedgerRepository(getIt<DioClient>());

  LedgerAmountVoucherKind get kind => widget.kind;

  String _ledgerLabel(Ledger l) {
    final code = l.code;
    return (code == null || code.isEmpty) ? l.name : '$code — ${l.name}';
  }

  LineInput? _lineInput(LedgerAmountLine row) {
    if (!row.isComplete) return null;
    return LineInput(quantity: Decimal.one, price: row.amount);
  }

  Widget _header(LedgerAmountFormCubit cubit, LedgerAmountFormState state) {
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
          const SizedBox(height: 12),
          FkLookupField<Ledger>(
            label: 'Cash / Bank ledger',
            value: state.cashBank,
            enabled: !posting,
            helperText:
                'Source of funds (payment) or deposit account (receipt)',
            displayOf: _ledgerLabel,
            loader: (q) async {
              final r = await _ledgerRepo.list(PageQuery(search: q));
              return r.fold((_) => const [], (p) => p.items);
            },
            onSelected: (l) => cubit.setCashBank(l, _ledgerLabel),
            validator: (v) => v == null ? 'Cash/Bank is required' : null,
          ),
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

  List<LineItemColumn<LedgerAmountLine>> _columns(
    LedgerAmountFormCubit cubit,
    LedgerAmountFormState state,
  ) {
    final posting = state.posting;
    return [
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
          enabled: !posting,
          displayOf: _ledgerLabel,
          loader: (q) async {
            final r = await _ledgerRepo.list(PageQuery(search: q));
            return r.fold((_) => const [], (p) => p.items);
          },
          onSelected: (l) {
            if (l == null) {
              cubit.updateLine(
                i,
                row.copyWith(ledgerId: null, ledgerLabel: null),
              );
              return;
            }
            cubit.updateLine(
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
          enabled: !posting,
          onChanged: (v) =>
              cubit.updateLine(i, row.copyWith(amount: v ?? Decimal.zero)),
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
  }

  @override
  Widget build(BuildContext context) {
    final bp = kind.blueprint;
    return BlocListener<LedgerAmountFormCubit, LedgerAmountFormState>(
      listenWhen: (p, c) => p.posted != c.posted && c.posted != null,
      listener: (context, state) {
        final posted = state.posted!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Posted ${posted.voucherNo} · ${posted.total}'),
          ),
        );
        context.go(kind.detailRoute(posted.id));
      },
      child: BlocBuilder<LedgerAmountFormCubit, LedgerAmountFormState>(
        builder: (context, state) {
          final cubit = context.read<LedgerAmountFormCubit>();
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
                    header: _header(cubit, state),
                    rows: state.draft.lines,
                    columns: _columns(cubit, state),
                    onRowsChanged: cubit.setLines,
                    newRow: LedgerAmountLine.new,
                    lineInputsOf: _lineInput,
                    onPost: () => cubit.submit(
                      formIsValid: () =>
                          _formKey.currentState?.validate() ?? false,
                    ),
                    postLabel: kind.createLabel,
                    posting: state.posting,
                    enabled: !state.posting,
                    errorText: state.error,
                    totalsLabel: 'Total',
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
