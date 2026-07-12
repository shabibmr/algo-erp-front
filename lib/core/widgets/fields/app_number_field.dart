import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Integer-typed form field. Keeps the raw text in the field but parses to
/// `int` at the validator/onChanged boundary, so callers never juggle
/// `String → int` themselves. Digits-only input is enforced with a
/// formatter, not just a validator, so bad input can't even be typed.
///
/// ```dart
/// AppNumberField(
///   label: 'Reorder level',
///   initialValue: 10,
///   onChanged: (v) => setState(() => reorderLevel = v),
/// )
/// ```
class AppNumberField extends StatelessWidget {
  const AppNumberField({
    required this.label,
    super.key,
    this.initialValue,
    this.helperText,
    this.hintText,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.enabled = true,
    this.allowNegative = false,
    this.controller,
    this.labelWidget,
  });

  final String label;

  /// Renders instead of [label] when set — e.g. a `FieldLabel` carrying the
  /// required marker.
  final Widget? labelWidget;
  final int? initialValue;
  final String? helperText;
  final String? hintText;

  /// Receives the parsed int, or null if the field is empty/unparsable.
  final FormFieldValidator<int?>? validator;
  final ValueChanged<int?>? onChanged;
  final FormFieldSetter<int?>? onSaved;
  final bool enabled;
  final bool allowNegative;
  final TextEditingController? controller;

  int? _parse(String? text) =>
      (text == null || text.isEmpty) ? null : int.tryParse(text);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue?.toString() : null,
      enabled: enabled,
      keyboardType: TextInputType.numberWithOptions(signed: allowNegative),
      inputFormatters: [
        if (allowNegative)
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*$'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      validator: validator == null ? null : (text) => validator!(_parse(text)),
      onChanged: onChanged == null ? null : (text) => onChanged!(_parse(text)),
      onSaved: onSaved == null ? null : (text) => onSaved!(_parse(text)),
      decoration: InputDecoration(
        label: labelWidget,
        labelText: labelWidget == null ? label : null,
        hintText: hintText,
        helperText: helperText,
      ),
    );
  }
}
