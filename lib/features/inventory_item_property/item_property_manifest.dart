import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/features/inventory_item_property/domain/item_property.dart';

/// ItemProperty's manifest. `rbacModule` is the coarse `'Inventory'` string
/// (`inventory.routes.ts`). Hard delete (no soft-delete column). The backend
/// has no `PUT /inventory/property/:id`, so `supportsUpdate: false` — edit
/// mode renders read-only instead of a broken Save button.
final itemPropertyManifest = EntityManifest<ItemProperty>(
  id: 'item-property',
  label: 'Item property',
  rbacModule: 'Inventory',
  resourcePath: '/inventory/property',
  listColumns: [
    FieldSpec<ItemProperty>(
      key: 'itemId',
      label: 'Item ID',
      type: FieldType.text,
      required: true,
      cellValue: (p) => p.itemId,
    ),
    FieldSpec<ItemProperty>(
      key: 'defaultValue',
      label: 'Default value',
      type: FieldType.text,
      cellValue: (p) => p.defaultValue ?? '—',
    ),
  ],
  searchFields: const ['itemId'],
  formFields: [
    FormFieldSpec<ItemProperty>(
      key: 'itemId',
      wireKey: 'Item_ID',
      label: 'Item ID',
      type: FieldType.text,
      required: true,
      getValue: (p) => p.itemId,
      setValue: (p, v) => p.copyWith(itemId: v as String?),
    ),
    FormFieldSpec<ItemProperty>(
      key: 'defaultValue',
      wireKey: 'Default_Value',
      label: 'Default value',
      type: FieldType.text,
      getValue: (p) => p.defaultValue,
      setValue: (p, v) => p.copyWith(defaultValue: v),
    ),
  ],
  emptyEntity: () => const ItemProperty(id: 0, propertyId: '', itemId: ''),
  hardDelete: true,
  supportsUpdate: false,
);
