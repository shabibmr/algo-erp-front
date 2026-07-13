import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Integer-typed form field. Keeps the raw text in the field but parses to
/// `int` at the validator/onChanged boundary, so callers never juggle
/// `String → int` themselves. Digits-only input is enforced with a
/// formatter, not just a validator, so bad input can't even be typed.
///
/// [value] is *controlled*: a value written back by a bloc after the field is
/// on screen reaches the visible text. Pass a [controller] instead to own the
/// text yourself, in which case [value] is ignored.
///
/// ```dart
/// AppNumberField(
///   label: 'Reorder level',
///   value: state.reorderLevel,
///   onChanged: (v) => context.read<Bloc>().add(ReorderLevelChanged(v)),
/// )
/// ```
class AppNumberField extends StatefulWidget {
  const AppNumberField({
    required this.label,
    super.key,
    this.value,
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
  final int? value;
  final String? helperText;
  final String? hintText;

  /// Receives the parsed int, or null if the field is empty/unparsable.
  final FormFieldValidator<int?>? validator;
  final ValueChanged<int?>? onChanged;
  final FormFieldSetter<int?>? onSaved;
  final bool enabled;
  final bool allowNegative;
  final TextEditingController? controller;

  @override
  State<AppNumberField> createState() => _AppNumberFieldState();
}

class _AppNumberFieldState extends State<AppNumberField> {
  late final TextEditingController _controller;
  late final bool _ownsController;

  static int? _parse(String? text) =>
      (text == null || text.isEmpty) ? null : int.tryParse(text);

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void didUpdateWidget(AppNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ownsController || widget.value == oldWidget.value) return;
    // Compare the parsed value so an echo of what the user just typed doesn't
    // rewrite the text and shove the caret to the end.
    if (widget.value == _parse(_controller.text)) return;
    final next = widget.value?.toString() ?? '';
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: TextInputType.numberWithOptions(
        signed: widget.allowNegative,
      ),
      inputFormatters: [
        if (widget.allowNegative)
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*$'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      validator: widget.validator == null
          ? null
          : (text) => widget.validator!(_parse(text)),
      onChanged: widget.onChanged == null
          ? null
          : (text) => widget.onChanged!(_parse(text)),
      onSaved: widget.onSaved == null
          ? null
          : (text) => widget.onSaved!(_parse(text)),
      decoration: InputDecoration(
        label: widget.labelWidget,
        labelText: widget.labelWidget == null ? widget.label : null,
        hintText: widget.hintText,
        helperText: widget.helperText,
      ),
    );
  }
}
