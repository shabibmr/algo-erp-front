import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:flutter/material.dart';

/// A labeled boolean toggle for form use (e.g. `is_active`), styled to sit
/// naturally in the same form column as the other `Field` widgets rather
/// than as a bare `Switch.adaptive`.
///
/// ```dart
/// AppSwitchField(
///   label: 'Active',
///   value: isActive,
///   onChanged: (v) => setState(() => isActive = v),
/// )
/// ```
class AppSwitchField extends StatelessWidget {
  const AppSwitchField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.helperText,
    this.enabled = true,
    this.labelWidget,
  });

  final String label;

  /// Renders instead of [label] when set — e.g. a `FieldLabel` carrying the
  /// required marker.
  final Widget? labelWidget;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? helperText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: tokens.spacing.xxs),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: labelWidget ?? Text(label),
        subtitle: helperText == null ? null : Text(helperText!),
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}
