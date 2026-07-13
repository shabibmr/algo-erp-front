import 'package:algo_erp_front/core/theme/app_theme.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

/// Stands in for a bloc: whatever `onChanged` reports is fed straight back in
/// as `value` on the next build. That round trip is what makes a naively
/// controlled field shove the caret to the end on every keystroke.
class _EchoField extends StatefulWidget {
  const _EchoField();

  @override
  State<_EchoField> createState() => _EchoFieldState();
}

class _EchoFieldState extends State<_EchoField> {
  String? _value;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'Billing name',
      value: _value,
      onChanged: (v) => setState(() => _value = v),
    );
  }
}

void main() {
  testWidgets('shows the label and reports changes', (tester) async {
    String? changed;
    await tester.pumpWidget(
      _wrap(AppTextField(label: 'Brand name', onChanged: (v) => changed = v)),
    );

    expect(find.text('Brand name'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Acme');
    expect(changed, 'Acme');
  });

  testWidgets('runs the validator and surfaces its error text', (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      _wrap(
        Form(
          key: formKey,
          child: AppTextField(
            label: 'Brand name',
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('a value written after mount reaches the visible text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const AppTextField(label: 'Billing name', value: 'Acme')),
    );
    expect(find.text('Acme'), findsOneWidget);

    // The bloc writes a new value — an FK selection autofilling the name.
    await tester.pumpWidget(
      _wrap(const AppTextField(label: 'Billing name', value: 'Globex')),
    );

    expect(find.text('Globex'), findsOneWidget);
    expect(find.text('Acme'), findsNothing);
  });

  testWidgets('clears the text when the value is nulled out', (tester) async {
    await tester.pumpWidget(
      _wrap(const AppTextField(label: 'Billing name', value: 'Acme')),
    );
    await tester.pumpWidget(_wrap(const AppTextField(label: 'Billing name')));

    expect(find.text('Acme'), findsNothing);
  });

  testWidgets('leaves the caret alone when the value echoes back', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const _EchoField()));

    final editable = find.byType(EditableText);
    await tester.tap(editable);
    await tester.pump();

    // Type with the caret parked mid-string, exactly as a user editing the
    // middle of a word would.
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'Acme',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump();

    final state = tester.state<EditableTextState>(editable);
    expect(state.textEditingValue.text, 'Acme');
    expect(state.textEditingValue.selection.baseOffset, 2);
  });

  testWidgets('does not dispose a controller it does not own', (tester) async {
    final controller = TextEditingController(text: 'Acme');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _wrap(AppTextField(label: 'Brand name', controller: controller)),
    );
    await tester.pumpWidget(_wrap(const SizedBox()));

    // Touching a disposed controller throws, so this asserts we left it alone.
    expect(controller.text, 'Acme');
  });
}
