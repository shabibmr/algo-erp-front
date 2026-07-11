import 'package:algo_erp_front/core/utils/extensions/format_x.dart';
import 'package:flutter/material.dart';

/// Read-only text field that opens `showDatePicker` on tap. Displays via
/// `DateTimeFormatX.toDayString()` so the on-screen format matches every
/// other date shown in the app. The underlying value stays a `DateTime` —
/// this widget never hands back a formatted string.
///
/// ```dart
/// AppDateField(
///   label: 'Voucher date',
///   value: voucherDate,
///   onChanged: (d) => setState(() => voucherDate = d),
/// )
/// ```
class AppDateField extends StatelessWidget {
  const AppDateField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.firstDate,
    this.lastDate,
    this.helperText,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? helperText;
  final FormFieldValidator<DateTime?>? validator;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: firstDate ?? DateTime(now.year - 10),
      lastDate: lastDate ?? DateTime(now.year + 10),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime?>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        return InkWell(
          onTap: enabled ? () => _pick(context) : null,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              helperText: helperText,
              errorText: state.errorText,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
              enabled: enabled,
            ),
            child: Text(
              value == null ? '' : value!.toDayString(),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        );
      },
    );
  }
}
