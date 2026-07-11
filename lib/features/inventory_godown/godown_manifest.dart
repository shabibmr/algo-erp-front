import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';

/// Godown's manifest — first Inventory-batch entity with more than one
/// `FieldType.bool` flag. `rbacModule` is `'Inventory'`.
final godownManifest = EntityManifest<Godown>(
  id: 'godown',
  label: 'Godown',
  rbacModule: 'Inventory',
  resourcePath: '/inventory/godown',
  listColumns: [
    FieldSpec<Godown>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      cellValue: (g) => g.name,
    ),
    FieldSpec<Godown>(
      key: 'location',
      label: 'Location',
      type: FieldType.text,
      cellValue: (g) => g.location ?? '—',
    ),
    FieldSpec<Godown>(
      key: 'isDefault',
      label: 'Default',
      type: FieldType.bool,
      cellValue: (g) => g.isDefault ? 'Yes' : 'No',
    ),
  ],
  searchFields: const ['name', 'code'],
  formFields: [
    FormFieldSpec<Godown>(
      key: 'name',
      wireKey: 'Godown_Name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      getValue: (g) => g.name,
      setValue: (g, v) => g.copyWith(name: v as String?),
    ),
    FormFieldSpec<Godown>(
      key: 'code',
      wireKey: 'godown_code',
      label: 'Code',
      type: FieldType.text,
      getValue: (g) => g.code,
      setValue: (g, v) => g.copyWith(code: v),
    ),
    FormFieldSpec<Godown>(
      key: 'location',
      wireKey: 'Godown_Location',
      label: 'Location',
      type: FieldType.text,
      getValue: (g) => g.location,
      setValue: (g, v) => g.copyWith(location: v),
    ),
    FormFieldSpec<Godown>(
      key: 'narration',
      wireKey: 'Godown_Narration',
      label: 'Narration',
      type: FieldType.text,
      getValue: (g) => g.narration,
      setValue: (g, v) => g.copyWith(narration: v),
    ),
    FormFieldSpec<Godown>(
      key: 'isProfitCentre',
      wireKey: 'is_profit_centre',
      label: 'Profit centre',
      type: FieldType.bool,
      getValue: (g) => g.isProfitCentre,
      setValue: (g, v) => g.copyWith(isProfitCentre: v as bool?),
    ),
    FormFieldSpec<Godown>(
      key: 'isDefault',
      wireKey: 'is_default',
      label: 'Default',
      type: FieldType.bool,
      getValue: (g) => g.isDefault,
      setValue: (g, v) => g.copyWith(isDefault: v as bool?),
    ),
    FormFieldSpec<Godown>(
      key: 'isProduction',
      wireKey: 'is_production',
      label: 'Production',
      type: FieldType.bool,
      getValue: (g) => g.isProduction,
      setValue: (g, v) => g.copyWith(isProduction: v as bool?),
    ),
  ],
  emptyEntity: () => const Godown(id: 0, name: ''),
  hardDelete: true,
);
