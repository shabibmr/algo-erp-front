import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/features/inventory_tax_category/domain/tax_category.dart';
import 'package:decimal/decimal.dart';

/// TaxCategories's manifest — first Inventory-batch entity to use
/// `FieldType.decimal` and soft delete (`is_active`) instead of Brand's
/// hard-delete pattern. `rbacModule` is `'Inventory'`.
final taxCategoryManifest = EntityManifest<TaxCategory>(
  id: 'tax-category',
  label: 'Tax category',
  rbacModule: 'Inventory',
  resourcePath: '/inventory/tax-category',
  listColumns: [
    FieldSpec<TaxCategory>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      cellValue: (t) => t.name,
    ),
    FieldSpec<TaxCategory>(
      key: 'rate',
      label: 'Rate %',
      type: FieldType.decimal,
      cellValue: (t) => t.rate.toString(),
    ),
    FieldSpec<TaxCategory>(
      key: 'isActive',
      label: 'Active',
      type: FieldType.bool,
      cellValue: (t) => t.isActive ? 'Yes' : 'No',
    ),
  ],
  searchFields: const ['name'],
  formFields: [
    FormFieldSpec<TaxCategory>(
      key: 'name',
      wireKey: 'tax_name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      getValue: (t) => t.name,
      setValue: (t, v) => t.copyWith(name: v as String?),
    ),
    FormFieldSpec<TaxCategory>(
      key: 'rate',
      wireKey: 'tax_rate',
      label: 'Rate %',
      type: FieldType.decimal,
      required: true,
      getValue: (t) => t.rate,
      setValue: (t, v) => t.copyWith(rate: v as Decimal? ?? Decimal.zero),
    ),
    FormFieldSpec<TaxCategory>(
      key: 'isActive',
      wireKey: 'is_active',
      label: 'Active',
      type: FieldType.bool,
      getValue: (t) => t.isActive,
      setValue: (t, v) => t.copyWith(isActive: v as bool?),
    ),
  ],
  emptyEntity: () => TaxCategory(id: 0, name: '', rate: Decimal.zero),
);
