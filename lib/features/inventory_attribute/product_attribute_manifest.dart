import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/features/inventory_attribute/domain/product_attribute.dart';

final productAttributeManifest = EntityManifest<ProductAttribute>(
  id: 'product-attribute',
  label: 'Product attribute',
  rbacModule: 'Inventory',
  resourcePath: '/inventory/attribute',
  listColumns: [
    FieldSpec<ProductAttribute>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      cellValue: (attr) => attr.name,
    ),
    FieldSpec<ProductAttribute>(
      key: 'code',
      label: 'Code',
      type: FieldType.text,
      cellValue: (attr) => attr.code ?? '—',
    ),
    FieldSpec<ProductAttribute>(
      key: 'type',
      label: 'Type',
      type: FieldType.text,
      cellValue: (attr) => attr.type.label,
    ),
    FieldSpec<ProductAttribute>(
      key: 'parentName',
      label: 'Group',
      type: FieldType.text,
      cellValue: (attr) => attr.parentName ?? '—',
    ),
    FieldSpec<ProductAttribute>(
      key: 'unit',
      label: 'Unit',
      type: FieldType.text,
      cellValue: (attr) => attr.unit ?? '—',
    ),
    FieldSpec<ProductAttribute>(
      key: 'isActive',
      label: 'Active',
      type: FieldType.bool,
      cellValue: (attr) => attr.isActive ? 'Yes' : 'No',
    ),
  ],
  searchFields: const ['attribute_name', 'attribute_code'],
  formFields: [
    FormFieldSpec<ProductAttribute>(
      key: 'name',
      wireKey: 'attribute_name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      getValue: (attr) => attr.name,
      setValue: (attr, v) => attr.copyWith(name: v as String?),
    ),
    FormFieldSpec<ProductAttribute>(
      key: 'code',
      wireKey: 'attribute_code',
      label: 'Code',
      type: FieldType.text,
      getValue: (attr) => attr.code,
      setValue: (attr, v) => attr.copyWith(code: v as String?),
    ),
    FormFieldSpec<ProductAttribute>(
      key: 'type',
      wireKey: 'attribute_type',
      label: 'Attribute Type',
      type: FieldType.singleSelect,
      required: true,
      selectOptions: AttributeType.values
          .map((t) => (value: t.wireValue, label: t.label))
          .toList(),
      getValue: (attr) => attr.type.wireValue,
      setValue: (attr, v) => attr.copyWith(
        type: AttributeType.fromWire(v as String?),
      ),
    ),
    FormFieldSpec<ProductAttribute>(
      key: 'unit',
      wireKey: 'unit',
      label: 'Unit',
      type: FieldType.text,
      helperText: 'e.g. inches, cm, etc.',
      getValue: (attr) => attr.unit,
      setValue: (attr, v) => attr.copyWith(unit: v as String?),
    ),
    FormFieldSpec<ProductAttribute>(
      key: 'isActive',
      wireKey: 'is_active',
      label: 'Active',
      type: FieldType.bool,
      getValue: (attr) => attr.isActive,
      setValue: (attr, v) => attr.copyWith(isActive: v as bool? ?? true),
    ),
  ],
  emptyEntity: () => const ProductAttribute(id: 0, name: ''),
  hardDelete: false,
);
