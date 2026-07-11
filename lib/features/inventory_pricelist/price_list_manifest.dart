import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/features/inventory_pricelist/domain/price_list.dart';

/// PriceList's manifest. `rbacModule` is `'Inventory'`. First Inventory-batch
/// entity to use `FieldType.dateTime` in a form (start/end dates).
final priceListManifest = EntityManifest<PriceList>(
  id: 'pricelist',
  label: 'Price list',
  rbacModule: 'Inventory',
  resourcePath: '/inventory/pricelist',
  listColumns: [
    FieldSpec<PriceList>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      cellValue: (p) => p.name,
    ),
    FieldSpec<PriceList>(
      key: 'isDefault',
      label: 'Default',
      type: FieldType.bool,
      cellValue: (p) => p.isDefault ? 'Yes' : 'No',
    ),
  ],
  searchFields: const ['name'],
  formFields: [
    FormFieldSpec<PriceList>(
      key: 'name',
      wireKey: 'Price_List_Name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      getValue: (p) => p.name,
      setValue: (p, v) => p.copyWith(name: v as String?),
    ),
    FormFieldSpec<PriceList>(
      key: 'startDate',
      wireKey: 'Price_List_Start_Date',
      label: 'Start date',
      type: FieldType.dateTime,
      getValue: (p) => p.startDate,
      setValue: (p, v) => p.copyWith(startDate: v),
    ),
    FormFieldSpec<PriceList>(
      key: 'endDate',
      wireKey: 'Price_List_End_Date',
      label: 'End date',
      type: FieldType.dateTime,
      getValue: (p) => p.endDate,
      setValue: (p, v) => p.copyWith(endDate: v),
    ),
    FormFieldSpec<PriceList>(
      key: 'isDefault',
      wireKey: 'Price_List_Default',
      label: 'Default',
      type: FieldType.bool,
      getValue: (p) => p.isDefault,
      setValue: (p, v) => p.copyWith(isDefault: v as bool?),
    ),
    FormFieldSpec<PriceList>(
      key: 'showInPos',
      wireKey: 'Price_List_ShowInPos',
      label: 'Show in POS',
      type: FieldType.bool,
      getValue: (p) => p.showInPos,
      setValue: (p, v) => p.copyWith(showInPos: v as bool?),
    ),
    FormFieldSpec<PriceList>(
      key: 'isOnline',
      wireKey: 'Price_List_isOnline',
      label: 'Online',
      type: FieldType.bool,
      getValue: (p) => p.isOnline,
      setValue: (p, v) => p.copyWith(isOnline: v as bool?),
    ),
  ],
  emptyEntity: () => const PriceList(id: 0, name: ''),
  hardDelete: true,
);
