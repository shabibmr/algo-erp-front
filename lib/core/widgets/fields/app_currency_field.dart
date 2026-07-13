import 'package:algo_erp_front/core/widgets/fields/app_decimal_field.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

/// Money-typed field: an [AppDecimalField] with a currency prefix and 2
/// decimal places by default, matching `DecimalFormatX.toMoney()`'s
/// convention elsewhere in the app. Kept as a distinct widget (not just a
/// parameterized decimal field) so voucher/line-item forms read clearly at
/// the call site and the currency symbol can later become tenant-driven
/// without touching every call site.
///
/// ```dart
/// AppCurrencyField(
///   label: 'Unit price',
///   value: line.unitPrice,
///   onChanged: (v) => context.read<Bloc>().add(PriceChanged(v)),
/// )
/// ```
class AppCurrencyField extends StatelessWidget {
  const AppCurrencyField({
    required this.label,
    super.key,
    this.value,
    this.helperText,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.enabled = true,
    this.currencySymbol = 'AED',
    this.controller,
  });

  final String label;
  final Decimal? value;
  final String? helperText;
  final FormFieldValidator<Decimal?>? validator;
  final ValueChanged<Decimal?>? onChanged;
  final FormFieldSetter<Decimal?>? onSaved;
  final bool enabled;
  final String currencySymbol;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return AppDecimalField(
      label: label,
      value: value,
      helperText: helperText,
      validator: validator,
      onChanged: onChanged,
      onSaved: onSaved,
      enabled: enabled,
      maxDecimals: 2,
      controller: controller,
      prefixText: currencySymbol,
    );
  }
}
