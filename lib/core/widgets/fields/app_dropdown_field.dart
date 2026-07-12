import 'package:flutter/material.dart';

/// Generic single-select dropdown form field — the typed alternative to
/// hand-rolling `DropdownButtonFormField<T>` per screen. Callers supply the
/// option list and a display-label selector; everything else (styling,
/// validator wiring) matches the rest of `fields/`.
///
/// ```dart
/// AppDropdownField<Category>(
///   label: 'Category',
///   value: selectedCategory,
///   items: categories,
///   labelOf: (c) => c.name,
///   onChanged: (c) => setState(() => selectedCategory = c),
/// )
/// ```
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    required this.label,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    super.key,
    this.value,
    this.helperText,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final List<T> items;
  final String Function(T item) labelOf;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final String? helperText;
  final FormFieldValidator<T>? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      validator: validator,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(labelText: label, helperText: helperText),
      items: [
        for (final item in items)
          DropdownMenuItem<T>(value: item, child: Text(labelOf(item))),
      ],
    );
  }
}
