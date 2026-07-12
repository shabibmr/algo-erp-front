import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_batch/domain/item_batch.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:algo_erp_front/features/inventory_item/inventory_item_di.dart';
import 'package:decimal/decimal.dart';

final _inventoryItemRepository = createInventoryItemRepository(
  getIt<DioClient>(),
);

/// Item batch master. Soft delete. RBAC coarse `'Inventory'`.
final itemBatchManifest = EntityManifest<ItemBatch>(
  id: 'item-batch',
  label: 'Batch',
  rbacModule: 'Inventory',
  resourcePath: '/inventory/batch',
  listColumns: [
    FieldSpec<ItemBatch>(
      key: 'batchNumber',
      label: 'Batch #',
      type: FieldType.text,
      required: true,
      cellValue: (b) => b.batchNumber,
    ),
    FieldSpec<ItemBatch>(
      key: 'itemId',
      label: 'Item id',
      type: FieldType.int,
      cellValue: (b) => b.itemId.toString(),
    ),
    FieldSpec<ItemBatch>(
      key: 'sellingPrice',
      label: 'Selling',
      type: FieldType.decimal,
      cellValue: (b) => b.sellingPrice.toString(),
    ),
    FieldSpec<ItemBatch>(
      key: 'expirationDate',
      label: 'Expires',
      type: FieldType.dateTime,
      cellValue: (b) {
        final d = b.expirationDate;
        if (d == null) return '—';
        return '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';
      },
    ),
    FieldSpec<ItemBatch>(
      key: 'isActive',
      label: 'Active',
      type: FieldType.bool,
      cellValue: (b) => b.isActive ? 'Yes' : 'No',
    ),
  ],
  searchFields: const ['batch_number'],
  formFields: [
    FormFieldSpec<ItemBatch>(
      key: 'itemId',
      wireKey: 'item_id',
      label: 'Item',
      type: FieldType.fk,
      required: true,
      getValue: (b) => b.itemId == 0 ? null : b.itemId,
      setValue: (b, v) =>
          b.copyWith(itemId: v == null ? 0 : (v as InventoryItem).id),
      fkSearch: (query) async {
        final result = await _inventoryItemRepository.list(
          PageQuery(search: query),
        );
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
      validator: (v) {
        // getValue may be null for empty draft; setValue stores 0 until pick.
        if (v == null) return 'Item is required';
        return null;
      },
    ),
    FormFieldSpec<ItemBatch>(
      key: 'batchNumber',
      wireKey: 'batch_number',
      label: 'Batch number',
      type: FieldType.text,
      required: true,
      getValue: (b) => b.batchNumber,
      setValue: (b, v) => b.copyWith(batchNumber: v as String? ?? ''),
    ),
    FormFieldSpec<ItemBatch>(
      key: 'manufacturingDate',
      wireKey: 'manufacturing_date',
      label: 'Manufacturing date',
      type: FieldType.dateTime,
      getValue: (b) => b.manufacturingDate,
      setValue: (b, v) => b.copyWith(manufacturingDate: v as DateTime?),
    ),
    FormFieldSpec<ItemBatch>(
      key: 'expirationDate',
      wireKey: 'expiration_date',
      label: 'Expiration date',
      type: FieldType.dateTime,
      getValue: (b) => b.expirationDate,
      setValue: (b, v) => b.copyWith(expirationDate: v as DateTime?),
    ),
    FormFieldSpec<ItemBatch>(
      key: 'costPrice',
      wireKey: 'cost_price',
      label: 'Cost price',
      type: FieldType.decimal,
      getValue: (b) => b.costPrice,
      setValue: (b, v) =>
          b.copyWith(costPrice: (v as Decimal?) ?? Decimal.zero),
    ),
    FormFieldSpec<ItemBatch>(
      key: 'sellingPrice',
      wireKey: 'selling_price',
      label: 'Selling price',
      type: FieldType.decimal,
      getValue: (b) => b.sellingPrice,
      setValue: (b, v) =>
          b.copyWith(sellingPrice: (v as Decimal?) ?? Decimal.zero),
    ),
    FormFieldSpec<ItemBatch>(
      key: 'isActive',
      wireKey: 'is_active',
      label: 'Active',
      type: FieldType.bool,
      getValue: (b) => b.isActive,
      setValue: (b, v) => b.copyWith(isActive: v as bool?),
    ),
  ],
  emptyEntity: () => ItemBatch(
    id: 0,
    itemId: 0,
    batchNumber: '',
    costPrice: Decimal.zero,
    sellingPrice: Decimal.zero,
  ),
);
