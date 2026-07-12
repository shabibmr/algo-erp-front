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
}
