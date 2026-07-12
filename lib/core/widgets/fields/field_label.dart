import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:flutter/material.dart';

/// A form field's label, with a brass asterisk when the field is required.
///
/// Brass, not red: a required field isn't an error, it's an instruction. Red is
/// held back for the moment something actually goes wrong, so it still means
/// something when it appears.
class FieldLabel extends StatelessWidget {
  const FieldLabel({required this.text, super.key, this.isRequired = false});

  final String text;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    if (!isRequired) return Text(text);
    final tokens = context.tokens;
    return Text.rich(
      TextSpan(
        text: text,
        children: [
          TextSpan(
            text: ' *',
            style: TextStyle(color: tokens.brand.brass),
            semanticsLabel: 'required',
          ),
        ],
      ),
    );
  }
}
