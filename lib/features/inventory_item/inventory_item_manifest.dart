import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/inventory_brand/brand_di.dart';
import 'package:algo_erp_front/features/inventory_brand/domain/brand.dart';
import 'package:algo_erp_front/features/inventory_category/category_di.dart';
import 'package:algo_erp_front/features/inventory_category/domain/category.dart';
import 'package:algo_erp_front/features/inventory_group/domain/inventory_group.dart';
import 'package:algo_erp_front/features/inventory_group/inventory_group_di.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:algo_erp_front/features/inventory_tax_category/domain/tax_category.dart';
import 'package:algo_erp_front/features/inventory_tax_category/tax_category_di.dart';
import 'package:algo_erp_front/features/inventory_uom/domain/uom.dart';
import 'package:algo_erp_front/features/inventory_uom/uom_di.dart';
import 'package:decimal/decimal.dart';

/// Lazy FK targets — same-module (Brand/UOM/group/…) + cross-module Ledger.
final _inventoryGroupRepository = createInventoryGroupRepository(
  getIt<DioClient>(),
);
final _uomRepository = createUomRepository(getIt<DioClient>());
final _brandRepository = createBrandRepository(getIt<DioClient>());
final _categoryRepository = createCategoryRepository(getIt<DioClient>());
final _taxCategoryRepository = createTaxCategoryRepository(getIt<DioClient>());
final _ledgerRepository = createLedgerRepository(getIt<DioClient>());

Future<List<Object>> _searchLedgers(String query) async {
  final result = await _ledgerRepository.list(PageQuery(search: query));
  return result.fold((_) => const [], (page) => page.items);
}

String _ledgerLabel(Object item) {
  final l = item as Ledger;
  final code = l.code;
  return (code == null || code.isEmpty) ? l.name : '$code — ${l.name}';
}

Future<Object?> _resolveLedger(Object id) async {
  final result = await _ledgerRepository.getById(id as int);
  return result.fold((_) => null, (l) => l);
}

/// Inventory item master. RBAC is coarse `'Inventory'`.
final inventoryItemManifest = EntityManifest<InventoryItem>(
  id: 'inventory-item',
  label: 'Item',
  rbacModule: 'Inventory',
  resourcePath: '/inventory/item',
  listColumns: [
    FieldSpec<InventoryItem>(
      key: 'code',
      label: 'Code',
      type: FieldType.text,
      required: true,
      cellValue: (i) => i.code,
    ),
    FieldSpec<InventoryItem>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      cellValue: (i) => i.name,
    ),
    FieldSpec<InventoryItem>(
      key: 'price',
      label: 'Price',
      type: FieldType.decimal,
      cellValue: (i) => i.price.toString(),
    ),
    FieldSpec<InventoryItem>(
      key: 'isSalesItem',
      label: 'Sales',
      type: FieldType.bool,
      cellValue: (i) => i.isSalesItem ? 'Yes' : 'No',
    ),
    FieldSpec<InventoryItem>(
      key: 'isActive',
      label: 'Active',
      type: FieldType.bool,
      cellValue: (i) => i.isActive ? 'Yes' : 'No',
    ),
  ],
  searchFields: const ['Item_Name', 'Item_Alias', 'Item_Code'],
  formFields: [
    FormFieldSpec<InventoryItem>(
      key: 'code',
      wireKey: 'Item_Code',
      label: 'Code',
      type: FieldType.text,
      required: true,
      getValue: (i) => i.code,
      setValue: (i, v) => i.copyWith(code: v as String?),
    ),
    FormFieldSpec<InventoryItem>(
      key: 'name',
      wireKey: 'Item_Name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      getValue: (i) => i.name,
      setValue: (i, v) => i.copyWith(name: v as String?),
    ),
    FormFieldSpec<InventoryItem>(
      key: 'alias',
      wireKey: 'Item_Alias',
      label: 'Alias',
      type: FieldType.text,
      getValue: (i) => i.alias,
      setValue: (i, v) => i.copyWith(alias: v as String?),
    ),
    FormFieldSpec<InventoryItem>(
      key: 'partNumber',
      wireKey: 'Part_Number',
      label: 'Part number',
      type: FieldType.text,
      getValue: (i) => i.partNumber,
      setValue: (i, v) => i.copyWith(partNumber: v as String?),
    ),
    FormFieldSpec<InventoryItem>(
      key: 'description',
      wireKey: 'Item_Description',
      label: 'Description',
      type: FieldType.text,
      getValue: (i) => i.description,
      setValue: (i, v) => i.copyWith(description: v as String?),
    ),
    FormFieldSpec<InventoryItem>(
      key: 'nameArabic',
      wireKey: 'Item_Name_Arabic',
      label: 'Name (Arabic)',
      type: FieldType.text,
      getValue: (i) => i.nameArabic,
      setValue: (i, v) => i.copyWith(nameArabic: v as String?),
    ),
    FormFieldSpec<InventoryItem>(
      key: 'inventoryGroupId',
      wireKey: 'inventory_group_id',
      label: 'Item group',
      type: FieldType.fk,
      getValue: (i) => i.inventoryGroupId,
      setValue: (i, v) {
        if (v == null) {
          return i.copyWith(inventoryGroupId: null, legacyGroupKey: null);
        }
        final g = v as InventoryGroup;
        final legacy = g.groupId.isNotEmpty
            ? g.groupId
            : (g.code != null && g.code!.isNotEmpty ? g.code : g.id.toString());
        return i.copyWith(inventoryGroupId: g.id, legacyGroupKey: legacy);
      },
      fkSearch: (query) async {
        final result = await _inventoryGroupRepository.list(
          PageQuery(search: query),
        );
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) {
        final g = item as InventoryGroup;
        final path = g.fullPath;
        if (path != null && path.isNotEmpty) return path;
        final code = g.code;
        return (code == null || code.isEmpty) ? g.name : '$code — ${g.name}';
      },
      fkResolveById: (id) async {
        final result = await _inventoryGroupRepository.getById(id as int);
        return result.fold((_) => null, (g) => g);
      },
    ),
    FormFieldSpec<InventoryItem>(
      key: 'uomId',
      wireKey: 'uom_id',
      label: 'UOM',
      type: FieldType.fk,
      getValue: (i) => i.uomId,
      setValue: (i, v) => i.copyWith(uomId: v == null ? null : (v as Uom).id),
      fkSearch: (query) async {
        final result = await _uomRepository.list(PageQuery(search: query));
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) {
        final u = item as Uom;
        final code = u.code;
        return (code == null || code.isEmpty) ? u.name : '$code — ${u.name}';
      },
      fkResolveById: (id) async {
        final result = await _uomRepository.getById(id as int);
        return result.fold((_) => null, (u) => u);
      },
    ),
    FormFieldSpec<InventoryItem>(
      key: 'brandId',
      wireKey: 'inventory_brand_id',
      label: 'Brand',
      type: FieldType.fk,
      getValue: (i) => i.brandId,
      setValue: (i, v) =>
          i.copyWith(brandId: v == null ? null : (v as Brand).id),
      fkSearch: (query) async {
        final result = await _brandRepository.list(PageQuery(search: query));
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) => (item as Brand).name,
      fkResolveById: (id) async {
        final result = await _brandRepository.getById(id as int);
        return result.fold((_) => null, (b) => b);
      },
    ),
    FormFieldSpec<InventoryItem>(
      key: 'categoryId',
      wireKey: 'category_id',
      label: 'Category',
      type: FieldType.fk,
      getValue: (i) => i.categoryId,
      setValue: (i, v) =>
          i.copyWith(categoryId: v == null ? null : (v as Category).id),
      fkSearch: (query) async {
        final result = await _categoryRepository.list(PageQuery(search: query));
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) => (item as Category).name,
      fkResolveById: (id) async {
        final result = await _categoryRepository.getById(id as int);
        return result.fold((_) => null, (c) => c);
      },
    ),
    FormFieldSpec<InventoryItem>(
      key: 'taxCategoryId',
      wireKey: 'default_tax_category_id',
      label: 'Tax category',
      type: FieldType.fk,
      getValue: (i) => i.taxCategoryId,
      setValue: (i, v) =>
          i.copyWith(taxCategoryId: v == null ? null : (v as TaxCategory).id),
      fkSearch: (query) async {
        final result = await _taxCategoryRepository.list(
          PageQuery(search: query),
        );
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) {
        final t = item as TaxCategory;
        return '${t.name} (${t.rate}%)';
      },
      fkResolveById: (id) async {
        final result = await _taxCategoryRepository.getById(id as int);
        return result.fold((_) => null, (t) => t);
      },
    ),
    FormFieldSpec<InventoryItem>(
      key: 'price',
      wireKey: 'Price',
      label: 'Price',
      type: FieldType.decimal,
      required: true,
      getValue: (i) => i.price,
      setValue: (i, v) => i.copyWith(price: (v as Decimal?) ?? Decimal.zero),
    ),
    FormFieldSpec<InventoryItem>(
      key: 'basePrice',
      wireKey: 'base_price',
      label: 'Base price',
      type: FieldType.decimal,
      getValue: (i) => i.basePrice,
      setValue: (i, v) =>
          i.copyWith(basePrice: (v as Decimal?) ?? Decimal.zero),
    ),
    FormFieldSpec<InventoryItem>(
      key: 'standardCost',
      wireKey: 'standard_cost',
      label: 'Standard cost',
      type: FieldType.decimal,
      getValue: (i) => i.standardCost,
      setValue: (i, v) =>
          i.copyWith(standardCost: (v as Decimal?) ?? Decimal.zero),
    ),
    FormFieldSpec<InventoryItem>(
      key: 'vatRate',
      wireKey: 'Vat_Rate',
      label: 'VAT rate %',
      type: FieldType.decimal,
      getValue: (i) => i.vatRate,
      setValue: (i, v) => i.copyWith(vatRate: (v as Decimal?) ?? Decimal.zero),
    ),
    FormFieldSpec<InventoryItem>(
      key: 'openingStock',
      wireKey: 'Opening_Stock',
      label: 'Opening stock',
      type: FieldType.decimal,
      getValue: (i) => i.openingStock,
      setValue: (i, v) =>
          i.copyWith(openingStock: (v as Decimal?) ?? Decimal.zero),
    ),
    FormFieldSpec<InventoryItem>(
      key: 'reorderLevel',
      wireKey: 'Reorder_Level',
      label: 'Reorder level',
      type: FieldType.decimal,
      getValue: (i) => i.reorderLevel,
      setValue: (i, v) =>
          i.copyWith(reorderLevel: (v as Decimal?) ?? Decimal.zero),
    ),
    FormFieldSpec<InventoryItem>(
      key: 'salesGlLedgerId',
      wireKey: 'sales_gl_ledger_id',
      label: 'Sales GL ledger',
      type: FieldType.fk,
      getValue: (i) => i.salesGlLedgerId,
      setValue: (i, v) =>
          i.copyWith(salesGlLedgerId: v == null ? null : (v as Ledger).id),
      fkSearch: _searchLedgers,
      fkDisplayOf: _ledgerLabel,
      fkResolveById: _resolveLedger,
    ),
    FormFieldSpec<InventoryItem>(
      key: 'defaultPurchaseLedgerId',
      wireKey: 'default_purchase_ledger_id',
      label: 'Purchase ledger',
      type: FieldType.fk,
      getValue: (i) => i.defaultPurchaseLedgerId,
      setValue: (i, v) => i.copyWith(
        defaultPurchaseLedgerId: v == null ? null : (v as Ledger).id,
      ),
      fkSearch: _searchLedgers,
      fkDisplayOf: _ledgerLabel,
      fkResolveById: _resolveLedger,
    ),
    FormFieldSpec<InventoryItem>(
      key: 'defaultSalesReturnLedgerId',
      wireKey: 'default_sales_return_ledger_id',
      label: 'Sales return ledger',
      type: FieldType.fk,
      getValue: (i) => i.defaultSalesReturnLedgerId,
      setValue: (i, v) => i.copyWith(
        defaultSalesReturnLedgerId: v == null ? null : (v as Ledger).id,
      ),
      fkSearch: _searchLedgers,
      fkDisplayOf: _ledgerLabel,
      fkResolveById: _resolveLedger,
    ),
    FormFieldSpec<InventoryItem>(
      key: 'defaultPurchaseReturnLedgerId',
      wireKey: 'default_purchase_return_ledger_id',
      label: 'Purchase return ledger',
      type: FieldType.fk,
      getValue: (i) => i.defaultPurchaseReturnLedgerId,
      setValue: (i, v) => i.copyWith(
        defaultPurchaseReturnLedgerId: v == null ? null : (v as Ledger).id,
      ),
      fkSearch: _searchLedgers,
      fkDisplayOf: _ledgerLabel,
      fkResolveById: _resolveLedger,
    ),
    FormFieldSpec<InventoryItem>(
      key: 'isPurchaseItem',
      wireKey: 'is_purchase_item',
      label: 'Purchase item',
      type: FieldType.bool,
      getValue: (i) => i.isPurchaseItem,
      setValue: (i, v) => i.copyWith(isPurchaseItem: v as bool?),
    ),
    FormFieldSpec<InventoryItem>(
      key: 'isSalesItem',
      wireKey: 'is_sales_item',
      label: 'Sales item',
      type: FieldType.bool,
      getValue: (i) => i.isSalesItem,
      setValue: (i, v) => i.copyWith(isSalesItem: v as bool?),
    ),
    FormFieldSpec<InventoryItem>(
      key: 'isStockItem',
      wireKey: 'is_stock_item',
      label: 'Stock item',
      type: FieldType.bool,
      getValue: (i) => i.isStockItem,
      setValue: (i, v) => i.copyWith(isStockItem: v as bool?),
    ),
    FormFieldSpec<InventoryItem>(
      key: 'isSerialized',
      wireKey: 'is_serialized',
      label: 'Serialized',
      type: FieldType.bool,
      getValue: (i) => i.isSerialized,
      setValue: (i, v) => i.copyWith(isSerialized: v as bool?),
    ),
    FormFieldSpec<InventoryItem>(
      key: 'isBatchTracked',
      wireKey: 'is_batch_tracked',
      label: 'Batch tracked',
      type: FieldType.bool,
      getValue: (i) => i.isBatchTracked,
      setValue: (i, v) => i.copyWith(isBatchTracked: v as bool?),
    ),
    FormFieldSpec<InventoryItem>(
      key: 'isService',
      wireKey: 'is_service',
      label: 'Service',
      type: FieldType.bool,
      getValue: (i) => i.isService,
      setValue: (i, v) => i.copyWith(isService: v as bool?),
    ),
    FormFieldSpec<InventoryItem>(
      key: 'isPerishable',
      wireKey: 'is_perishable',
      label: 'Perishable',
      type: FieldType.bool,
      getValue: (i) => i.isPerishable,
      setValue: (i, v) => i.copyWith(isPerishable: v as bool?),
    ),
    FormFieldSpec<InventoryItem>(
      key: 'isActive',
      wireKey: 'is_active',
      label: 'Active',
      type: FieldType.bool,
      getValue: (i) => i.isActive,
      setValue: (i, v) => i.copyWith(isActive: v as bool?),
    ),
  ],
  emptyEntity: () => InventoryItem(
    id: 0,
    name: '',
    code: '',
    price: Decimal.zero,
    basePrice: Decimal.zero,
    standardCost: Decimal.zero,
    vatRate: Decimal.zero,
    openingStock: Decimal.zero,
    reorderLevel: Decimal.zero,
  ),
);
