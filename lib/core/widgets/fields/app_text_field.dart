import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The house plain-text form field. Every other typed field in `fields/`
/// wraps this same shape (label + validator hook + RTL-safe padding) so a
/// form built from a mix of `AppTextField`, `AppNumberField`, etc. reads as
/// one consistent system — style tweaks belong in
/// `AppTheme.inputDecorationTheme`, not here.
///
/// ```dart
/// AppTextField(
///   label: 'Brand name',
///   controller: _nameController,
///   validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
/// )
/// ```
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    super.key,
    this.controller,
    this.initialValue,
    this.hintText,
    this.helperText,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.autovalidateMode,
    this.labelWidget,
  });

  final String label;

  /// Renders instead of [label] when set — e.g. a `FieldLabel` carrying the
  /// required marker.
  final Widget? labelWidget;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final String? helperText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final FormFieldSetter<String>? onSaved;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onSaved: onSaved,
      autovalidateMode: autovalidateMode,
      decoration: InputDecoration(
        label: labelWidget,
        labelText: labelWidget == null ? label : null,
        hintText: hintText,
        helperText: helperText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
