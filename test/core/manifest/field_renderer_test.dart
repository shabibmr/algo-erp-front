import 'package:algo_erp_front/core/manifest/field_renderer.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/theme/app_theme.dart';
import 'package:algo_erp_front/core/widgets/fields/app_date_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_decimal_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_number_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_switch_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:algo_erp_front/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _E {
  const _E();
}

FormFieldSpec<_E> _field(
  FieldType type, {
  Future<List<Object>> Function(String)? fkSearch,
  String Function(Object)? fkDisplayOf,
  Future<Object?> Function(Object)? fkResolveById,
}) {
  return FormFieldSpec<_E>(
    key: 'f',
    label: 'Field',
    type: type,
    getValue: (_) => null,
    setValue: (e, _) => e,
    fkSearch: fkSearch,
    fkDisplayOf: fkDisplayOf,
    fkResolveById: fkResolveById,
  );
}

void main() {
  Widget build(Widget child) => MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets('FieldType.text renders AppTextField', (tester) async {
    await tester.pumpWidget(
      build(
        FieldRenderer.build<_E>(
          field: _field(FieldType.text),
          value: null,
          onChanged: (_) {},
          enabled: true,
        ),
      ),
    );
    expect(find.byType(AppTextField), findsOneWidget);
  });

  testWidgets('FieldType.int renders AppNumberField', (tester) async {
    await tester.pumpWidget(
      build(
        FieldRenderer.build<_E>(
          field: _field(FieldType.int),
          value: null,
          onChanged: (_) {},
          enabled: true,
        ),
      ),
    );
    expect(find.byType(AppNumberField), findsOneWidget);
  });

  testWidgets('FieldType.decimal renders AppDecimalField', (tester) async {
    await tester.pumpWidget(
      build(
        FieldRenderer.build<_E>(
          field: _field(FieldType.decimal),
          value: null,
          onChanged: (_) {},
          enabled: true,
        ),
      ),
    );
    expect(find.byType(AppDecimalField), findsOneWidget);
  });

  testWidgets('FieldType.bool renders AppSwitchField', (tester) async {
    await tester.pumpWidget(
      build(
        FieldRenderer.build<_E>(
          field: _field(FieldType.bool),
          value: false,
          onChanged: (_) {},
          enabled: true,
        ),
      ),
    );
    expect(find.byType(AppSwitchField), findsOneWidget);
  });

  testWidgets('FieldType.dateTime renders AppDateField', (tester) async {
    await tester.pumpWidget(
      build(
        FieldRenderer.build<_E>(
          field: _field(FieldType.dateTime),
          value: null,
          onChanged: (_) {},
          enabled: true,
        ),
      ),
    );
    expect(find.byType(AppDateField), findsOneWidget);
  });

  testWidgets('FieldType.fk renders FkLookupField', (tester) async {
    await tester.pumpWidget(
      build(
        FieldRenderer.build<_E>(
          field: _field(
            FieldType.fk,
            fkSearch: (_) async => const [],
            fkDisplayOf: (item) => item.toString(),
            fkResolveById: (_) async => null,
          ),
          value: null,
          onChanged: (_) {},
          enabled: true,
        ),
      ),
    );
    expect(find.byType(FkLookupField<Object>), findsOneWidget);
  });

  testWidgets('errorText from server validation overrides field validator', (
    tester,
  ) async {
    final field = FormFieldSpec<_E>(
      key: 'f',
      label: 'Field',
      type: FieldType.text,
      getValue: (_) => null,
      setValue: (e, _) => e,
      validator: (_) => 'client error',
    );
    await tester.pumpWidget(
      build(
        Form(
          child: FieldRenderer.build<_E>(
            field: field,
            value: null,
            onChanged: (_) {},
            enabled: true,
            errorText: 'server error',
          ),
        ),
      ),
    );
    final formField = tester.widget<AppTextField>(find.byType(AppTextField));
    expect(formField.validator!(null), 'server error');
  });

  testWidgets('required field with no value fails validation', (tester) async {
    final field = FormFieldSpec<_E>(
      key: 'f',
      label: 'Field',
      type: FieldType.text,
      required: true,
      getValue: (_) => null,
      setValue: (e, _) => e,
    );
    await tester.pumpWidget(
      build(
        FieldRenderer.build<_E>(
          field: field,
          value: null,
          onChanged: (_) {},
          enabled: true,
        ),
      ),
    );
    final formField = tester.widget<AppTextField>(find.byType(AppTextField));
    expect(formField.validator!(null), 'Field is required');
  });
}
