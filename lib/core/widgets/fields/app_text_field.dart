import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The house plain-text form field. Every other typed field in `fields/`
/// wraps this same shape (label + validator hook + RTL-safe padding) so a
/// form built from a mix of `AppTextField`, `AppNumberField`, etc. reads as
/// one consistent system — style tweaks belong in
/// `AppTheme.inputDecorationTheme`, not here.
///
/// [value] is *controlled*: a value written back by a bloc after the field is
/// on screen (an FK selection that autofills a name, a source-document
/// conversion) reaches the visible text. Pass a [controller] instead to own
/// the text yourself, in which case [value] is ignored.
///
/// ```dart
/// AppTextField(
///   label: 'Brand name',
///   value: state.brandName,
///   onChanged: (v) => context.read<Bloc>().add(NameChanged(v)),
/// )
/// ```
class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.label,
    super.key,
    this.controller,
    this.value,
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
  final TextEditingController? controller;
  final String? value;
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
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final TextEditingController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ?? TextEditingController(text: widget.value ?? '');
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ownsController || widget.value == oldWidget.value) return;
    final next = widget.value ?? '';
    // The text already matching means the user typed this themselves and the
    // value is echoing back — reassigning would drive the caret to the end on
    // every keystroke.
    if (next == _controller.text) return;
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
      textAlign: widget.textAlign ?? TextAlign.start,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onSaved: widget.onSaved,
      autovalidateMode: widget.autovalidateMode,
      decoration: InputDecoration(
        label: widget.hideLabel ? null : widget.labelWidget,
        labelText: widget.hideLabel
            ? null
            : (widget.labelWidget == null ? widget.label : null),
        hintText: widget.hintText,
        helperText: widget.helperText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
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
