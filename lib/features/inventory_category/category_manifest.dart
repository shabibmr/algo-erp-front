import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/features/inventory_category/domain/category.dart';

/// Category's manifest. `rbacModule` is `'Inventory'`, matching every other
/// `/inventory/**` route's coarse `authorize()` gate.
final categoryManifest = EntityManifest<Category>(
  id: 'category',
  label: 'Category',
  rbacModule: 'Inventory',
  resourcePath: '/inventory/category',
  listColumns: [
    FieldSpec<Category>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      cellValue: (c) => c.name,
    ),
    FieldSpec<Category>(
      key: 'code',
      label: 'Code',
      type: FieldType.text,
      cellValue: (c) => c.code ?? '—',
    ),
  ],
  searchFields: const ['name', 'code'],
  formFields: [
    FormFieldSpec<Category>(
      key: 'name',
      wireKey: 'category_name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      getValue: (c) => c.name,
      setValue: (c, v) => c.copyWith(name: v as String?),
    ),
    FormFieldSpec<Category>(
      key: 'code',
      wireKey: 'category_code',
      label: 'Code',
      type: FieldType.text,
      getValue: (c) => c.code,
      setValue: (c, v) => c.copyWith(code: v),
    ),
    FormFieldSpec<Category>(
      key: 'description',
      wireKey: 'Description',
      label: 'Description',
      type: FieldType.text,
      getValue: (c) => c.description,
      setValue: (c, v) => c.copyWith(description: v),
    ),
  ],
  emptyEntity: () => const Category(id: 0, name: ''),
  hardDelete: true,
);
