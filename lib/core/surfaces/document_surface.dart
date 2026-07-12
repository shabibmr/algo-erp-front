import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/domain/line_engine/line_engine.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/utils/extensions/format_x.dart';
import 'package:algo_erp_front/core/vouchers/voucher_blueprint.dart';
import 'package:algo_erp_front/core/widgets/data_display/line_item_grid.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

/// Shared voucher document chrome: header slot, line grid, live totals,
/// and primary lifecycle actions.
///
/// Feature packages own the header fields and line row type [R]; this
/// surface owns layout + totals display. Line math uses [lineInputsOf]
/// → [LineEngine] so totals stay pure and testable.
class DocumentSurface<R> extends StatelessWidget {
  const DocumentSurface({
    required this.blueprint,
    required this.header,
    required this.rows,
    required this.columns,
    required this.onRowsChanged,
    required this.lineInputsOf,
    required this.onPost,
    super.key,
    this.newRow,
    this.enabled = true,
    this.posting = false,
    this.errorText,
    this.onSaveDraft,
    this.totalsLabel = 'Totals',
    this.postLabel = 'Post',
    this.saveDraftLabel = 'Save draft',
  });

  final VoucherBlueprint blueprint;
  final Widget header;
  final List<R> rows;
  final List<LineItemColumn<R>> columns;
  final ValueChanged<List<R>> onRowsChanged;
  final R Function()? newRow;

  /// Map each row to [LineInput] for the engine (ignore incomplete rows
  /// by returning null — they are skipped in totals).
  final LineInput? Function(R row) lineInputsOf;

  final bool enabled;
  final bool posting;
  final String? errorText;

  final VoidCallback onPost;
  final VoidCallback? onSaveDraft;
  final String totalsLabel;
  final String postLabel;
  final String saveDraftLabel;

  DocumentTotals get _totals {
    final inputs = <LineInput>[];
    for (final row in rows) {
      final input = lineInputsOf(row);
      if (input != null) inputs.add(input);
    }
    return LineEngine.computeDocument(inputs);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final totals = _totals;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorText != null) ...[
          Container(
            padding: EdgeInsets.all(tokens.spacing.sm),
            decoration: BoxDecoration(
              color: tokens.semanticColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(tokens.radii.sm),
            ),
            child: Text(
              errorText!,
              style: TextStyle(color: tokens.semanticColors.danger),
            ),
          ),
          SizedBox(height: tokens.spacing.md),
        ],
        header,
        SizedBox(height: tokens.spacing.md),
        Text('Lines', style: theme.textTheme.titleMedium),
        SizedBox(height: tokens.spacing.sm),
        Expanded(
          child: SingleChildScrollView(
            child: LineItemGrid<R>(
              rows: rows,
              columns: columns,
              onChanged: onRowsChanged,
              newRow: enabled ? newRow : null,
              enabled: enabled && !posting,
            ),
          ),
        ),
        SizedBox(height: tokens.spacing.md),
        _TotalsBar(
          label: totalsLabel,
          subtotal: totals.subtotal,
          discount: totals.discount,
          tax: totals.tax,
          total: totals.total,
        ),
        SizedBox(height: tokens.spacing.md),
        Row(
          children: [
            if (onSaveDraft != null &&
                blueprint.lifecycle.contains(VoucherLifecycleAction.saveDraft))
              PermissionGate(
                module: blueprint.rbacModule,
                action: PermissionAction.create,
                child: OutlinedButton(
                  onPressed: (enabled && !posting) ? onSaveDraft : null,
                  child: Text(saveDraftLabel),
                ),
              ),
            if (onSaveDraft != null) SizedBox(width: tokens.spacing.sm),
            if (blueprint.lifecycle.contains(VoucherLifecycleAction.post))
              PermissionGate(
                module: blueprint.rbacModule,
                action: PermissionAction.create,
                child: FilledButton(
                  onPressed: (enabled && !posting) ? onPost : null,
                  child: Text(posting ? 'Posting…' : postLabel),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TotalsBar extends StatelessWidget {
  const _TotalsBar({
    required this.label,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
  });

  final String label;
  final Decimal subtotal;
  final Decimal discount;
  final Decimal tax;
  final Decimal total;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    Widget row(String k, Decimal v, {bool emphasize = false}) => Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            k,
            style: emphasize
                ? theme.textTheme.titleMedium
                : theme.textTheme.bodyMedium,
          ),
          Text(
            v.toMoney(),
            style: emphasize
                ? theme.textTheme.titleMedium
                : theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: theme.textTheme.titleSmall),
            SizedBox(height: tokens.spacing.sm),
            row('Subtotal', subtotal),
            row('Discount', discount),
            row('VAT', tax),
            const Divider(),
            row('Total', total, emphasize: true),
          ],
        ),
      ),
    );
  }
}
