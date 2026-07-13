import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/features/organization_currency/domain/currency.dart';

/// Currency's manifest. `rbacModule` is `'Currency'` — Organization gates per
/// entity (`organization.routes.ts`). Soft delete, so the default
/// `hardDelete: false` stands.
final currencyManifest = EntityManifest<Currency>(
  id: 'currency',
  label: 'Currency',
  rbacModule: 'Currency',
  resourcePath: '/organization/currencies',
  listColumns: [
    FieldSpec<Currency>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      cellValue: (c) => c.name,
    ),
    FieldSpec<Currency>(
      key: 'isoCode',
      label: 'ISO',
      type: FieldType.text,
      cellValue: (c) => c.isoCode,
    ),
    FieldSpec<Currency>(
      key: 'symbol',
      label: 'Symbol',
      type: FieldType.text,
      cellValue: (c) => c.symbol ?? '—',
    ),
  ],
  searchFields: const ['name', 'isoCode'],
  formFields: [
    FormFieldSpec<Currency>(
      key: 'name',
      wireKey: 'currency_name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      getValue: (c) => c.name,
      setValue: (c, v) => c.copyWith(name: v as String?),
    ),
    FormFieldSpec<Currency>(
      key: 'isoCode',
      wireKey: 'iso_code',
      label: 'ISO code',
      type: FieldType.text,
      hintText: 'AED',
      helperText: 'Exactly 3 characters',
      getValue: (c) => c.isoCode,
      setValue: (c, v) => c.copyWith(isoCode: v as String?),
      // currencySchema: z.string().length(3)
      validator: (v) {
        final text = v as String?;
        if (text == null || text.isEmpty) return null;
        return text.length == 3 ? null : 'Must be exactly 3 characters';
      },
    ),
    FormFieldSpec<Currency>(
      key: 'symbol',
      wireKey: 'symbol',
      label: 'Symbol',
      type: FieldType.text,
      getValue: (c) => c.symbol,
      setValue: (c, v) => c.copyWith(symbol: v),
    ),
    FormFieldSpec<Currency>(
      key: 'decimalPlaces',
      wireKey: 'decimal_places',
      label: 'Decimal places',
      type: FieldType.int,
      getValue: (c) => c.decimalPlaces,
      setValue: (c, v) => c.copyWith(decimalPlaces: v as int? ?? 2),
    ),
    FormFieldSpec<Currency>(
      key: 'isBaseCurrency',
      wireKey: 'is_base_currency',
      label: 'Base currency',
      type: FieldType.bool,
      getValue: (c) => c.isBaseCurrency,
      setValue: (c, v) => c.copyWith(isBaseCurrency: v as bool?),
    ),
  ],
  emptyEntity: () => const Currency(id: 0, isoCode: '', name: ''),
);
