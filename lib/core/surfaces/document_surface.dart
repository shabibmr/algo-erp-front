import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/line_engine/line_engine.dart';
import 'package:algo_erp_front/core/responsive/breakpoints.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/utils/extensions/format_x.dart';
import 'package:algo_erp_front/core/vouchers/voucher_blueprint.dart';
import 'package:algo_erp_front/core/widgets/data_display/line_item_grid.dart';
import 'package:algo_erp_front/core/widgets/layout/work_canvas.dart';
import 'package:algo_erp_front/core/widgets/layout/work_sheet.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared voucher document chrome: header slot, line grid, live totals,
/// and primary lifecycle actions.
///
/// Feature packages own the header fields and line row type [R]; this
/// surface owns layout + totals display. Line math uses [lineInputsOf]
/// → [LineEngine] so totals stay pure and testable.
class DocumentSurface<R> extends StatefulWidget {
  const DocumentSurface({
    required this.blueprint,
    required this.rows,
    required this.columns,
    required this.onRowsChanged,
    required this.lineInputsOf,
    required this.onPost,
    super.key,
    this.header,
    this.newRow,
    this.keyOf,
    this.enabled = true,
    this.posting = false,
    this.errorText,
    this.onSaveDraft,
    this.footer,
    this.totalsLabel = 'Summary',
    this.postLabel = 'Post',
    this.saveDraftLabel = 'Save draft',
    this.topBar,
    this.linesLabel = 'Items',
    this.saveDraftCaption,
    this.postCaption,
    this.linesViewportHeight = 420,
    this.rowSearchFilter,
  });

  final VoucherBlueprint blueprint;

  /// Header fields above the line grid. Omit it when the voucher puts its
  /// header in [topBar] instead — no empty slot is rendered.
  final Widget? header;
  final List<R> rows;
  final List<LineItemColumn<R>> columns;
  final ValueChanged<List<R>> onRowsChanged;
  final R Function()? newRow;
  final Widget? topBar;

  /// Forwarded to [LineItemGrid.keyOf] — supply it whenever `R` has a stable
  /// id, so a row's fields survive the row above it being removed.
  final Object Function(R row, int index)? keyOf;

  /// Optional slot rendered after the line grid and before totals — e.g. a
  /// narration box. Omit for vouchers that don't need one.
  final Widget? footer;

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

  /// Section title above the line grid (mock: "Items").
  final String linesLabel;

  /// Optional helper under Save draft.
  final String? saveDraftCaption;

  /// Optional helper under Post.
  final String? postCaption;

  /// Viewport height for the scrollable line grid.
  final double linesViewportHeight;

  /// Optional function to filter grid rows by search query.
  final bool Function(R row, String query)? rowSearchFilter;

  @override
  State<DocumentSurface<R>> createState() => _DocumentSurfaceState<R>();
}

class _DocumentSurfaceState<R> extends State<DocumentSurface<R>> {
  bool _searchExpanded = false;
  String _searchQuery = '';

  DocumentTotals get _totals {
    final inputs = <LineInput>[];
    for (final row in widget.rows) {
      final input = widget.lineInputsOf(row);
      if (input != null) inputs.add(input);
    }
    return LineEngine.computeDocument(inputs);
  }

  bool get _canCommit =>
      getIt<PermissionService>().can(
        widget.blueprint.rbacModule,
        PermissionAction.create,
      ) &&
      widget.enabled &&
      !widget.posting;

  /// Ctrl/Cmd+S — save draft. Mirrors the Save-draft button's guards exactly
  /// (handler present, lifecycle, permission, enabled/not-posting) so the
  /// shortcut can never fire an action the button itself wouldn't.
  void _saveDraftShortcut() {
    final onSaveDraft = widget.onSaveDraft;
    if (onSaveDraft == null || !_canCommit) return;
    if (!widget.blueprint.lifecycle.contains(
      VoucherLifecycleAction.saveDraft,
    )) {
      return;
    }
    onSaveDraft();
  }

  /// Ctrl/Cmd+Enter — post. Mirrors the Post button's guards.
  void _postShortcut() {
    if (!_canCommit) return;
    if (!widget.blueprint.lifecycle.contains(VoucherLifecycleAction.post)) {
      return;
    }
    widget.onPost();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final totals = _totals;
    final theme = Theme.of(context);

    final isDesktop = Breakpoints.isDesktop(context);

    Widget itemsGrid = SizedBox(
      height: widget.linesViewportHeight,
      child: SingleChildScrollView(
        child: LineItemGrid<R>(
          rows: widget.rows,
          columns: widget.columns,
          onChanged: widget.onRowsChanged,
          newRow: widget.enabled ? widget.newRow : null,
          keyOf: widget.keyOf,
          enabled: widget.enabled && !widget.posting,
          rowSearchFilter: widget.rowSearchFilter,
          searchQuery: _searchQuery,
        ),
      ),
    );

    if (isDesktop) {
      itemsGrid = Expanded(
        child: SingleChildScrollView(
          child: LineItemGrid<R>(
            rows: widget.rows,
            columns: widget.columns,
            onChanged: widget.onRowsChanged,
            newRow: widget.enabled ? widget.newRow : null,
            keyOf: widget.keyOf,
            enabled: widget.enabled && !widget.posting,
            rowSearchFilter: widget.rowSearchFilter,
            searchQuery: _searchQuery,
          ),
        ),
      );
    }

    final itemsContainer = WorkSheet(
      fill: isDesktop,
      toolbar: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.linesLabel, style: theme.textTheme.titleMedium),
          if (widget.rowSearchFilter != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _searchExpanded ? 200 : 36,
              height: 36,
              child: _searchExpanded
                  ? TextField(
                      autofocus: true,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Search items...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _searchExpanded = false;
                              _searchQuery = '';
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(tokens.radii.sm),
                          borderSide: BorderSide(color: tokens.brand.mist),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.search, size: 20),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _searchExpanded = true;
                        });
                      },
                    ),
            ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        tokens.spacing.md,
        tokens.spacing.sm,
        tokens.spacing.md,
        tokens.spacing.md,
      ),
      // The grid stays inside a Flex so its desktop `Expanded` has a parent.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [itemsGrid],
      ),
    );

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.errorText != null) ...[
          Container(
            padding: EdgeInsets.all(tokens.spacing.sm),
            decoration: BoxDecoration(
              color: tokens.semanticColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(tokens.radii.sm),
            ),
            child: Text(
              widget.errorText!,
              style: TextStyle(color: tokens.semanticColors.danger),
            ),
          ),
          SizedBox(height: tokens.spacing.md),
        ],
        if (widget.header != null) ...[
          widget.header!,
          SizedBox(height: tokens.spacing.sm),
        ],
        if (isDesktop) Expanded(child: itemsContainer) else itemsContainer,
        if (widget.footer != null) ...[
          SizedBox(height: tokens.spacing.sm),
          widget.footer!,
        ],
      ],
    );

    final hasCompleteLines = widget.rows.any(
      (r) => widget.lineInputsOf(r) != null,
    );

    final sidebar = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TotalsBar(
          label: widget.totalsLabel,
          subtotal: totals.subtotal,
          discount: totals.discount,
          tax: totals.tax,
          total: totals.total,
          showEmptyHint: !hasCompleteLines,
        ),
        if (isDesktop) const Spacer(),
        if (!isDesktop) SizedBox(height: tokens.spacing.md),
        Row(
          children: [
            if (widget.onSaveDraft != null &&
                widget.blueprint.lifecycle.contains(
                  VoucherLifecycleAction.saveDraft,
                ))
              Expanded(
                child: PermissionGate(
                  module: widget.blueprint.rbacModule,
                  action: PermissionAction.create,
                  child: OutlinedButton(
                    onPressed: (widget.enabled && !widget.posting)
                        ? widget.onSaveDraft
                        : null,
                    child: Text(widget.saveDraftLabel),
                  ),
                ),
              ),
            if (widget.onSaveDraft != null &&
                widget.blueprint.lifecycle.contains(
                  VoucherLifecycleAction.saveDraft,
                ) &&
                widget.blueprint.lifecycle.contains(
                  VoucherLifecycleAction.post,
                ))
              SizedBox(width: tokens.spacing.sm),
            if (widget.blueprint.lifecycle.contains(
              VoucherLifecycleAction.post,
            ))
              Expanded(
                child: PermissionGate(
                  module: widget.blueprint.rbacModule,
                  action: PermissionAction.create,
                  child: FilledButton(
                    onPressed: (widget.enabled && !widget.posting)
                        ? widget.onPost
                        : null,
                    child: Text(widget.posting ? 'Posting…' : widget.postLabel),
                  ),
                ),
              ),
          ],
        ),
      ],
    );

    return CallbackShortcuts(
      // Keyboard commit so a clerk never has to reach for the mouse. Both
      // control (Win/Linux) and meta (macOS) map to the same callback; the
      // callbacks self-guard, so a disabled surface just ignores the keys.
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            _saveDraftShortcut,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true):
            _saveDraftShortcut,
        const SingleActivator(LogicalKeyboardKey.enter, control: true):
            _postShortcut,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true):
            _postShortcut,
        const SingleActivator(LogicalKeyboardKey.numpadEnter, control: true):
            _postShortcut,
        const SingleActivator(LogicalKeyboardKey.numpadEnter, meta: true):
            _postShortcut,
      },
      child: WorkCanvas(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.topBar != null) ...[
              widget.topBar!,
              SizedBox(height: tokens.spacing.sm),
            ],
            Expanded(
              child: Breakpoints.isDesktop(context)
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 3, child: mainContent),
                        SizedBox(width: tokens.spacing.md),
                        SizedBox(width: 320, child: sidebar),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          mainContent,
                          SizedBox(height: tokens.spacing.md),
                          sidebar,
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
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
    this.showEmptyHint = false,
  });

  final String label;
  final Decimal subtotal;
  final Decimal discount;
  final Decimal tax;
  final Decimal total;
  final bool showEmptyHint;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final taxable = subtotal - discount;
    // Round-off not in engine yet — show zero so the mock line exists.
    final roundOff = Decimal.zero;

    Widget row(String k, Decimal v, {bool emphasize = false}) => Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.xxs),
      // The amount is laid out at its natural width and the label takes what's
      // left: in a 320px sidebar a seven-figure total must never be the thing
      // that gets clipped.
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              overflow: TextOverflow.ellipsis,
              // Grand total is a brass seal — "this is the money, this commits"
              // — not the lagoon of a clickable action.
              style: emphasize
                  ? theme.textTheme.titleMedium?.copyWith(
                      color: tokens.brand.brass,
                      fontWeight: FontWeight.w700,
                    )
                  : theme.textTheme.bodyMedium,
            ),
          ),
          SizedBox(width: tokens.spacing.sm),
          Text(
            v.toMoney(),
            // The document's headline figure: brass, in the Plex Mono figure
            // face so it reads as final money (§5.4). The rows above stay in
            // Plex-Sans tabular so the total deliberately stands apart.
            style: emphasize
                ? tokens.figures.copyWith(
                    color: tokens.brand.brass,
                    fontWeight: FontWeight.w700,
                    fontSize: theme.textTheme.titleMedium?.fontSize,
                  )
                : theme.textTheme.bodyMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
          ),
        ],
      ),
    );

    return WorkSheet(
      fill: false,
      title: label,
      padding: EdgeInsets.all(tokens.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          row('Items total', subtotal),
          row('Discount', discount),
          row('Taxable amount', taxable),
          row('Total tax', tax),
          row('Round off', roundOff),
          Divider(height: tokens.spacing.md, color: tokens.brand.mist),
          row('Grand total', total, emphasize: true),
          // The clerk's primary surface is desktop; a fresh voucher there was
          // a silent wall of zeros. Show the same cue on every breakpoint.
          if (showEmptyHint) ...[
            SizedBox(height: tokens.spacing.md),
            Container(
              padding: EdgeInsets.all(tokens.spacing.sm),
              decoration: BoxDecoration(
                color: tokens.brand.lagoonSoft.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(tokens.radii.sm),
                border: Border.all(
                  color: tokens.brand.lagoon.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: tokens.brand.lagoon,
                  ),
                  SizedBox(width: tokens.spacing.sm),
                  Expanded(
                    child: Text(
                      'Add items to see totals. '
                      'Values update as you complete lines.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.brand.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
