import 'package:algo_erp_front/core/theme/app_theme.dart';
import 'package:algo_erp_front/core/widgets/fields/app_decimal_field.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('parses the typed text to Decimal', (tester) async {
    Decimal? changed;
    await tester.pumpWidget(
      _wrap(AppDecimalField(label: 'Qty', onChanged: (v) => changed = v)),
    );

    await tester.enterText(find.byType(TextFormField), '2.5');
    expect(changed, Decimal.parse('2.5'));
  });

  testWidgets('a value written after mount reaches the visible text', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(AppDecimalField(label: 'Price')));
    expect(find.text('12.5'), findsNothing);

    // This is the sales-invoice bug: picking an item pushes the item's price
    // onto the line, and the Price cell has to show it.
    await tester.pumpWidget(
      _wrap(AppDecimalField(label: 'Price', value: Decimal.parse('12.5'))),
    );

    expect(find.text('12.5'), findsOneWidget);
  });

  testWidgets('does not rewrite text that is numerically the same value', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(AppDecimalField(label: 'Price', value: Decimal.parse('1.50'))),
    );

    final editable = find.byType(EditableText);
    await tester.tap(editable);
    await tester.pump();

    // The user has typed `1.50`; the bloc echoes back `1.5` — the same number.
    // Rewriting the box here would eat the trailing zero mid-typing.
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '1.50',
        selection: TextSelection.collapsed(offset: 4),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      _wrap(AppDecimalField(label: 'Price', value: Decimal.parse('1.5'))),
    );

    final state = tester.state<EditableTextState>(editable);
    expect(state.textEditingValue.text, '1.50');
    expect(state.textEditingValue.selection.baseOffset, 4);
  });
}
