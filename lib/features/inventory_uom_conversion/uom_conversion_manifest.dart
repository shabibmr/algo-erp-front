import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/features/inventory_uom_conversion/domain/uom_conversion.dart';

/// UOMConversion's manifest. `conversionValue` uses `FieldType.text` with a
/// numeric validator rather than `FieldType.decimal` — see the entity's doc
/// comment for why. `rbacModule` is `'Inventory'`.
final uomConversionManifest = EntityManifest<UomConversion>(
  id: 'uom-conversion',
  label: 'UOM conversion',
  rbacModule: 'Inventory',
  resourcePath: '/inventory/conversion',
  listColumns: [
    FieldSpec<UomConversion>(
      key: 'baseUnit',
      label: 'Base unit',
      type: FieldType.text,
      required: true,
      cellValue: (u) => u.baseUnit,
    ),
    FieldSpec<UomConversion>(
      key: 'toUnit',
      label: 'To unit',
      type: FieldType.text,
      required: true,
      cellValue: (u) => u.toUnit,
    ),
    FieldSpec<UomConversion>(
      key: 'conversionValue',
      label: 'Value',
      type: FieldType.text,
      cellValue: (u) => u.conversionValue,
    ),
  ],
  searchFields: const ['baseUnit', 'toUnit'],
  formFields: [
    FormFieldSpec<UomConversion>(
      key: 'baseUnit',
      wireKey: 'baseUnit',
      label: 'Base unit',
      type: FieldType.text,
      required: true,
      getValue: (u) => u.baseUnit,
      setValue: (u, v) => u.copyWith(baseUnit: v as String?),
    ),
    FormFieldSpec<UomConversion>(
      key: 'toUnit',
      wireKey: 'toUnit',
      label: 'To unit',
      type: FieldType.text,
      required: true,
      getValue: (u) => u.toUnit,
      setValue: (u, v) => u.copyWith(toUnit: v as String?),
    ),
    FormFieldSpec<UomConversion>(
      key: 'conversionValue',
      wireKey: 'conValue',
      label: 'Value',
      type: FieldType.text,
      required: true,
      getValue: (u) => u.conversionValue,
      setValue: (u, v) => u.copyWith(conversionValue: v as String?),
      validator: (v) {
        final text = v as String?;
        if (text == null || text.isEmpty) return null;
        return num.tryParse(text) == null ? 'Must be a number' : null;
      },
    ),
    FormFieldSpec<UomConversion>(
      key: 'itemId',
      wireKey: 'itemID',
      label: 'Item ID',
      type: FieldType.text,
      getValue: (u) => u.itemId,
      setValue: (u, v) => u.copyWith(itemId: v),
    ),
    FormFieldSpec<UomConversion>(
      key: 'narration',
      wireKey: 'narration',
      label: 'Narration',
      type: FieldType.text,
      getValue: (u) => u.narration,
      setValue: (u, v) => u.copyWith(narration: v),
    ),
  ],
  emptyEntity: () =>
      const UomConversion(id: 0, baseUnit: '', toUnit: '', conversionValue: ''),
  hardDelete: true,
);
