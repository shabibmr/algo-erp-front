import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/layout/field_widths.dart';
import 'package:flutter/material.dart';

/// One field in a stacked/paired form column: type drives max-width and pairing.
@immutable
class FormFieldLayoutItem {
  const FormFieldLayoutItem({
    required this.type,
    required this.child,
    this.half = false,
    this.maxWidthOverride,
  });

  final FieldType type;
  final Widget child;

  /// Prefer sharing a desktop row with the next half field.
  final bool half;

  /// When set, wins over type-based max width.
  final double? maxWidthOverride;
}

/// Shared form density: field max-widths, pairing, and inter-row gaps.
///
/// Used by master form surfaces and custom FieldRenderer lists (Ledger,
/// Employee, …) so every editor shares one rhythm.
abstract final class FormFieldLayout {
  /// Recommended max width for a control of [type]. `null` = stretch.
  static double? maxWidthForFieldType(FieldType type) {
    return switch (type) {
      FieldType.dateTime => FieldWidths.date,
      FieldType.int || FieldType.decimal => FieldWidths.number,
      FieldType.fk || FieldType.selfFk => FieldWidths.picker,
      // Names / descriptions / free text fill the column (or half-row).
      FieldType.text || FieldType.bool => null,
    };
  }

  /// Caps [child] so short controls stop filling an ultra-wide column.
  static Widget constrain(Widget child, {double? maxWidth}) {
    if (maxWidth == null) return child;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  static Widget wrapItem(FormFieldLayoutItem item) {
    final max =
        item.maxWidthOverride ?? maxWidthForFieldType(item.type);
    return constrain(item.child, maxWidth: max);
  }

  /// True when this field type can share a desktop row with another compact.
  static bool isPairable(FieldType type) {
    return switch (type) {
      FieldType.text ||
      FieldType.int ||
      FieldType.decimal ||
      FieldType.dateTime ||
      FieldType.fk ||
      FieldType.selfFk => true,
      // Switches are full-row chrome; pairing them with inputs looks broken.
      FieldType.bool => false,
    };
  }

  static bool shouldPair(FormFieldLayoutItem a, FormFieldLayoutItem b) {
    if (a.half && b.half) return true;
    if (a.half || b.half) return false;
    return isPairable(a.type) && isPairable(b.type);
  }

  /// Builds spaced rows; on non-mobile, pairs consecutive pairable fields.
  static List<Widget> buildRows(
    BuildContext context,
    List<FormFieldLayoutItem> items, {
    double? gap,
  }) {
    if (items.isEmpty) return const [];

    final tokens = context.tokens;
    final rowGap = gap ?? tokens.spacing.md;
    final pairUp = !context.isMobile;
    final rows = <Widget>[];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final next = i + 1 < items.length ? items[i + 1] : null;
      final pairs =
          pairUp && next != null && shouldPair(item, next);

      final row = pairs
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: wrapItem(item)),
                SizedBox(width: tokens.spacing.md),
                Expanded(child: wrapItem(next)),
              ],
            )
          : wrapItem(item);

      rows.add(
        Padding(
          padding: EdgeInsets.only(top: rows.isEmpty ? 0 : rowGap),
          child: row,
        ),
      );
      if (pairs) i++;
    }
    return rows;
  }

  /// Convenience: a scrollable column of [buildRows].
  static Widget column(
    BuildContext context,
    List<FormFieldLayoutItem> items, {
    double? gap,
    EdgeInsetsGeometry? padding,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.stretch,
  }) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (padding != null)
          Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: crossAxisAlignment,
              mainAxisSize: MainAxisSize.min,
              children: buildRows(context, items, gap: gap),
            ),
          )
        else
          ...buildRows(context, items, gap: gap),
      ],
    );
  }
}

/// Caps a free-form field widget (not from a form-field spec) by semantic
/// role — used by custom Card/voucher headers.
Widget constrainFormField(
  Widget child, {
  double? maxWidth,
}) =>
    FormFieldLayout.constrain(child, maxWidth: maxWidth);
