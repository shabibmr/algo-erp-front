import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/features/inventory_uom/domain/uom.dart';

/// UOM's manifest. `rbacModule` is `'Inventory'`, matching every other
/// `/inventory/**` route's coarse `authorize()` gate (`inventory.routes.ts`).
final uomManifest = EntityManifest<Uom>(
  id: 'uom',
  label: 'UOM',
  rbacModule: 'Inventory',
  resourcePath: '/inventory/uom',
  listColumns: [
    FieldSpec<Uom>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      cellValue: (u) => u.name,
    ),
    FieldSpec<Uom>(
      key: 'code',
      label: 'Code',
      type: FieldType.text,
      cellValue: (u) => u.code ?? '—',
    ),
    FieldSpec<Uom>(
      key: 'symbol',
      label: 'Symbol',
      type: FieldType.text,
      cellValue: (u) => u.symbol ?? '—',
    ),
  ],
  searchFields: const ['name', 'code'],
  formFields: [
    FormFieldSpec<Uom>(
      key: 'name',
      wireKey: 'uom_Name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      getValue: (u) => u.name,
      setValue: (u, v) => u.copyWith(name: v as String?),
    ),
    FormFieldSpec<Uom>(
      key: 'code',
      wireKey: 'uom_code',
      label: 'Code',
      type: FieldType.text,
      getValue: (u) => u.code,
      setValue: (u, v) => u.copyWith(code: v),
    ),
    FormFieldSpec<Uom>(
      key: 'symbol',
      wireKey: 'uom_symbol',
      label: 'Symbol',
      type: FieldType.text,
      getValue: (u) => u.symbol,
      setValue: (u, v) => u.copyWith(symbol: v),
    ),
    FormFieldSpec<Uom>(
      key: 'decimalPlaces',
      wireKey: 'decimal_places',
      label: 'Decimal places',
      type: FieldType.int,
      getValue: (u) => u.decimalPlaces,
      setValue: (u, v) => u.copyWith(decimalPlaces: v as int? ?? 0),
    ),
    FormFieldSpec<Uom>(
      key: 'isComposite',
      wireKey: 'is_Composite',
      label: 'Composite',
      type: FieldType.bool,
      getValue: (u) => u.isComposite,
      setValue: (u, v) => u.copyWith(isComposite: v as bool?),
    ),
  ],
  emptyEntity: () => const Uom(id: 0, name: ''),
  hardDelete: true,
);
