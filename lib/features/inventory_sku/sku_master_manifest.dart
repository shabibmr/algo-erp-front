import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:algo_erp_front/features/inventory_item/inventory_item_di.dart';
import 'package:algo_erp_front/features/inventory_sku/domain/sku_master.dart';
import 'package:decimal/decimal.dart';

final _inventoryItemRepository =
    createInventoryItemRepository(getIt<DioClient>());

/// SKU master. Hard delete. RBAC coarse `'Inventory'`.
final skuMasterManifest = EntityManifest<SkuMaster>(
  id: 'sku',
  label: 'SKU',
  rbacModule: 'Inventory',
  resourcePath: '/inventory/sku',
  listColumns: [
    FieldSpec<SkuMaster>(
      key: 'code',
      label: 'Code',
      type: FieldType.text,
      cellValue: (s) => s.code ?? '—',
    ),
    FieldSpec<SkuMaster>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      cellValue: (s) => s.name ?? '—',
    ),
    FieldSpec<SkuMaster>(
      key: 'barcode',
      label: 'Barcode',
      type: FieldType.text,
      cellValue: (s) => s.barcode ?? '—',
    ),
    FieldSpec<SkuMaster>(
      key: 'rate',
      label: 'Rate',
      type: FieldType.decimal,
      cellValue: (s) => s.rate?.toString() ?? '—',
    ),
  ],
  searchFields: const ['sku_name', 'sku_code', 'barcode'],
  formFields: [
    FormFieldSpec<SkuMaster>(
      key: 'inventoryItemId',
      wireKey: 'inventory_item_id',
      label: 'Item',
      type: FieldType.fk,
      getValue: (s) => s.inventoryItemId,
      setValue: (s, v) {
        if (v == null) {
          return s.copyWith(inventoryItemId: null);
        }
        final item = v as InventoryItem;
        final legacy = item.code.isNotEmpty ? item.code : item.id.toString();
        return s.copyWith(
          inventoryItemId: item.id,
          // Keep legacy ITEM_ID in sync when picking a parent item.
          itemId: s.itemId.isEmpty ? legacy : s.itemId,
        );
      },
      fkSearch: (query) async {
        final result =
            await _inventoryItemRepository.list(PageQuery(search: query));
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) {
        final i = item as InventoryItem;
        return '${i.code} — ${i.name}';
      },
      fkResolveById: (id) async {
        final result = await _inventoryItemRepository.getById(id as int);
        return result.fold((_) => null, (i) => i);
      },
    ),
    FormFieldSpec<SkuMaster>(
      key: 'itemId',
      wireKey: 'ITEM_ID',
      label: 'Legacy item ID',
      type: FieldType.text,
      required: true,
      helperText: 'Required by API; auto-filled from item code when possible',
      getValue: (s) => s.itemId,
      setValue: (s, v) => s.copyWith(itemId: v as String? ?? ''),
    ),
    FormFieldSpec<SkuMaster>(
      key: 'code',
      wireKey: 'sku_code',
      label: 'SKU code',
      type: FieldType.text,
      getValue: (s) => s.code,
      setValue: (s, v) => s.copyWith(code: v as String?),
    ),
    FormFieldSpec<SkuMaster>(
      key: 'name',
      wireKey: 'sku_name',
      label: 'Name',
      type: FieldType.text,
      getValue: (s) => s.name,
      setValue: (s, v) => s.copyWith(name: v as String?),
    ),
    FormFieldSpec<SkuMaster>(
      key: 'barcode',
      wireKey: 'barcode',
      label: 'Barcode',
      type: FieldType.text,
      getValue: (s) => s.barcode,
      setValue: (s, v) => s.copyWith(barcode: v as String?),
    ),
    FormFieldSpec<SkuMaster>(
      key: 'rate',
      wireKey: 'rate',
      label: 'Rate',
      type: FieldType.decimal,
      getValue: (s) => s.rate,
      setValue: (s, v) => s.copyWith(rate: v as Decimal?),
    ),
    FormFieldSpec<SkuMaster>(
      key: 'description',
      wireKey: 'SKU_DESCRIPTION',
      label: 'Description',
      type: FieldType.text,
      getValue: (s) => s.description,
      setValue: (s, v) => s.copyWith(description: v as String?),
    ),
    FormFieldSpec<SkuMaster>(
      key: 'skuType',
      wireKey: 'SKU_TYPE',
      label: 'Type (1/2/3)',
      type: FieldType.int,
      helperText: SkuMaster.skuTypes.entries
          .map((e) => '${e.key}=${e.value}')
          .join(', '),
      hintText: '1',
      getValue: (s) => s.skuType,
      setValue: (s, v) => s.copyWith(skuType: v as int?),
      validator: (v) {
        if (v == null) return null;
        final n = v as int;
        if (!SkuMaster.skuTypes.containsKey(n)) {
          return 'Must be 1, 2, or 3';
        }
        return null;
      },
    ),
    FormFieldSpec<SkuMaster>(
      key: 'value',
      wireKey: 'SKU_VALUE',
      label: 'Value',
      type: FieldType.text,
      getValue: (s) => s.value,
      setValue: (s, v) => s.copyWith(value: v as String?),
    ),
    FormFieldSpec<SkuMaster>(
      key: 'possibleValues',
      wireKey: 'SKU_POSSIBLE_VALUES',
      label: 'Possible values',
      type: FieldType.text,
      getValue: (s) => s.possibleValues,
      setValue: (s, v) => s.copyWith(possibleValues: v as String?),
    ),
  ],
  emptyEntity: () => const SkuMaster(id: 0, itemId: ''),
  hardDelete: true,
);
