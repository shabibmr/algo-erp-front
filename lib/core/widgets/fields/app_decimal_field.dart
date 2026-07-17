import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// [Decimal]-typed form field for quantities/rates — anything that must
/// stay loss-free like money but isn't itself a currency amount (see
/// `AppCurrencyField` for that). Never backs onto `double`: the raw text is
/// parsed straight to `package:decimal` `Decimal` per the house rule in
/// `docs/feature-contract.md`.
///
/// [value] is *controlled*: a value written back by a bloc after the field is
/// on screen (picking an item that carries a price, converting a source
/// document) reaches the visible text. Pass a [controller] instead to own the
/// text yourself, in which case [value] is ignored.
///
/// ```dart
/// AppDecimalField(
///   label: 'Quantity',
///   value: line.quantity,
///   onChanged: (v) => context.read<Bloc>().add(QtyChanged(v)),
/// )
/// ```
class AppDecimalField extends StatefulWidget {
  const AppDecimalField({
    required this.label,
    super.key,
    this.value,
    this.helperText,
    this.hintText,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.enabled = true,
    this.maxDecimals = 3,
    this.controller,
    this.prefixText,
    this.labelWidget,
    this.hideLabel = false,
    this.isBorderless = false,
    this.textAlign,
  });

  final String label;

  /// Renders instead of [label] when set — e.g. a `FieldLabel` carrying the
  /// required marker.
  final Widget? labelWidget;
  final bool hideLabel;
  final bool isBorderless;
  final TextAlign? textAlign;
  final Decimal? value;
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

  @override
  State<AppDecimalField> createState() => _AppDecimalFieldState();
}

class _AppDecimalFieldState extends State<AppDecimalField> {
  late final TextEditingController _controller;
  late final bool _ownsController;

  static Decimal? _parse(String? text) =>
      (text == null || text.isEmpty) ? null : Decimal.tryParse(text);

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void didUpdateWidget(AppDecimalField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ownsController || widget.value == oldWidget.value) return;
    // Compare the *parsed* value, not the raw text: `1.50` in the box and
    // `1.5` in state are the same number, and rewriting the text would drive
    // the caret to the end while the user is still typing.
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
      style: Theme.of(context).textTheme.bodyMedium,
      textAlign:
          widget.textAlign ??
          (widget.isBorderless ? TextAlign.right : TextAlign.start),
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(
            r'^\d*\.?\d{0,'
            '${widget.maxDecimals}}',
          ),
        ),
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
        label: widget.hideLabel ? null : widget.labelWidget,
        labelText: widget.hideLabel
            ? null
            : (widget.labelWidget == null ? widget.label : null),
        hintText: widget.hintText,
        helperText: widget.helperText,
        prefixText: widget.prefixText == null ? null : '${widget.prefixText} ',
        filled: !widget.isBorderless,
        border: widget.isBorderless ? InputBorder.none : null,
        enabledBorder: widget.isBorderless ? InputBorder.none : null,
        focusedBorder: widget.isBorderless
            ? UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              )
            : null,
      ),
    );
  }
}
