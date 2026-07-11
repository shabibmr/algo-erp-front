import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// [Decimal]-typed form field for quantities/rates — anything that must
/// stay loss-free like money but isn't itself a currency amount (see
/// `AppCurrencyField` for that). Never backs onto `double`: the raw text is
/// parsed straight to `package:decimal` `Decimal` per the house rule in
/// `docs/feature-contract.md`.
///
/// ```dart
/// AppDecimalField(
///   label: 'Quantity',
///   initialValue: line.quantity,
///   onChanged: (v) => setState(() => line.quantity = v),
/// )
/// ```
class AppDecimalField extends StatelessWidget {
  const AppDecimalField({
    required this.label,
    super.key,
    this.initialValue,
    this.helperText,
    this.hintText,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.enabled = true,
    this.maxDecimals = 3,
    this.controller,
    this.prefixText,
  });

  final String label;
  final Decimal? initialValue;
  final String? helperText;
  final String? hintText;

  /// Receives the parsed [Decimal], or null if empty/unparsable.
  final FormFieldValidator<Decimal?>? validator;
  final ValueChanged<Decimal?>? onChanged;
  final FormFieldSetter<Decimal?>? onSaved;
  final bool enabled;
  final int maxDecimals;
  final TextEditingController? controller;

  /// e.g. `'AED'` — used by `AppCurrencyField` to show a currency prefix.
  final String? prefixText;

  Decimal? _parse(String? text) =>
      (text == null || text.isEmpty) ? null : Decimal.tryParse(text);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue?.toString() : null,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(r'^\d*\.?\d{0,' '$maxDecimals}'),
        ),
      ],
      validator:
          validator == null ? null : (text) => validator!(_parse(text)),
      onChanged: onChanged == null ? null : (text) => onChanged!(_parse(text)),
      onSaved: onSaved == null ? null : (text) => onSaved!(_parse(text)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        helperText: helperText,
        prefixText: prefixText == null ? null : '$prefixText ',
      ),
    );
  }
}
