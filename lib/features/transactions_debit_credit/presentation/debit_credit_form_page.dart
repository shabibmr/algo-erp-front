import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_kind.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_models.dart';
import 'package:algo_erp_front/core/widgets/data_display/line_item_grid.dart';
import 'package:algo_erp_front/core/widgets/fields/app_date_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_decimal_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/layout/field_widths.dart';
import 'package:algo_erp_front/core/widgets/layout/form_field_layout.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/transactions_debit_credit/cubit/debit_credit_form_cubit.dart';
import 'package:algo_erp_front/features/transactions_debit_credit/debit_credit_di.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Create form for Journal / Contra with client-side DR/CR balance check.
class DebitCreditFormPage extends StatelessWidget {
  const DebitCreditFormPage({required this.kind, super.key});

  final DebitCreditVoucherKind kind;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DebitCreditFormCubit(
        kind: kind,
        repository: createDebitCreditRepository(getIt<DioClient>(), kind),
      ),
      child: _DebitCreditFormView(kind: kind),
    );
  }
}

class _DebitCreditFormView extends StatefulWidget {
  const _DebitCreditFormView({required this.kind});

  final DebitCreditVoucherKind kind;

  @override
  State<_DebitCreditFormView> createState() => _DebitCreditFormViewState();
}

class _DebitCreditFormViewState extends State<_DebitCreditFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _ledgerRepo = createLedgerRepository(getIt<DioClient>());

  DebitCreditVoucherKind get kind => widget.kind;

  String _ledgerLabel(Ledger l) {
    final code = l.code;
    return (code == null || code.isEmpty) ? l.name : '$code — ${l.name}';
  }

  Widget _header(DebitCreditFormCubit cubit, DebitCreditFormState state) {
    final draft = state.draft;
    final posting = state.posting;
    final tokens = context.tokens;
    final gap = SizedBox(height: tokens.spacing.md);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              constrainFormField(
                AppTextField(
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
                maxWidth: FieldWidths.code,
              ),
              SizedBox(width: tokens.spacing.md),
              constrainFormField(
                AppTextField(
                  label: 'Financial year',
                  value: draft.financialYear,
                  enabled: !posting,
                  onChanged: (v) =>
                      cubit.updateDraft(draft.copyWith(financialYear: v)),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                maxWidth: FieldWidths.code,
              ),
              SizedBox(width: tokens.spacing.md),
              constrainFormField(
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
                maxWidth: FieldWidths.date,
              ),
            ],
          ),
          gap,
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

  List<LineItemColumn<DebitCreditLine>> _columns(
    DebitCreditFormCubit cubit,
    DebitCreditFormState state,
  ) {
    final posting = state.posting;
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
    );

    if (cubit.isJournal) {
      return [
        ledgerCol,
        LineItemColumn(
          label: 'Debit',
          cellBuilder: (context, row, i) => AppDecimalField(
            label: 'Debit',
            value: row.debit,
            enabled: !posting,
            onChanged: (v) =>
                cubit.updateLine(i, row.copyWith(debit: v ?? Decimal.zero)),
          ),
        ),
        LineItemColumn(
          label: 'Credit',
          cellBuilder: (context, row, i) => AppDecimalField(
            label: 'Credit',
            value: row.credit,
            enabled: !posting,
            onChanged: (v) =>
                cubit.updateLine(i, row.copyWith(credit: v ?? Decimal.zero)),
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
              onChanged: posting
                  ? null
                  : (v) {
                      if (v != null) {
                        cubit.updateLine(i, row.copyWith(side: v));
                      }
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

  Widget _balanceBar(BuildContext context, DebitCreditFormCubit cubit) {
    final tokens = context.tokens;
    final t = cubit.totals;
    final balanced = cubit.balanced;
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
    return BlocListener<DebitCreditFormCubit, DebitCreditFormState>(
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
      child: BlocBuilder<DebitCreditFormCubit, DebitCreditFormState>(
        builder: (context, state) {
          final cubit = context.read<DebitCreditFormCubit>();
          return AdaptiveLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'New ${bp.label}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: tokens.spacing.md),
                if (state.error != null) ...[
                  Container(
                    padding: EdgeInsets.all(tokens.spacing.sm),
                    decoration: BoxDecoration(
                      color: tokens.semanticColors.danger.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(tokens.radii.sm),
                    ),
                    child: Text(
                      state.error!,
                      style: TextStyle(color: tokens.semanticColors.danger),
                    ),
                  ),
                  SizedBox(height: tokens.spacing.md),
                ],
                _header(cubit, state),
                SizedBox(height: tokens.spacing.md),
                Text('Lines', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: tokens.spacing.sm),
                Expanded(
                  child: SingleChildScrollView(
                    child: LineItemGrid<DebitCreditLine>(
                      rows: state.draft.lines,
                      columns: _columns(cubit, state),
                      onChanged: cubit.setLines,
                      newRow: state.posting ? null : DebitCreditLine.new,
                      enabled: !state.posting,
                    ),
                  ),
                ),
                SizedBox(height: tokens.spacing.md),
                _balanceBar(context, cubit),
                SizedBox(height: tokens.spacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: PermissionGate(
                    module: bp.rbacModule,
                    action: PermissionAction.create,
                    child: FilledButton(
                      onPressed: state.posting
                          ? null
                          : () => cubit.submit(
                              formIsValid: () =>
                                  _formKey.currentState?.validate() ?? false,
                            ),
                      child: state.posting
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
        },
      ),
    );
  }
}
