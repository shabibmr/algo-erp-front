import 'package:algo_erp_front/features/inventory_item/data/inventory_item_dto.dart';
import 'package:algo_erp_front/features/inventory_item/data/inventory_item_mapper.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = InventoryItemMapper();

  test("InventoryItemDto.fromJson reads the backend's wire casing", () {
    final dto = InventoryItemDto.fromJson(const {
      'id': 12,
      'Item_Name': 'Widget A',
      'Item_Code': 'W-001',
      'Item_Alias': 'WA',
      'Part_Number': 'P-9',
      'Item_Description': 'A sellable widget',
      'Item_Name_Arabic': 'قطعة',
      'inventory_group_id': 8,
      'Group_Id': 'G-FG',
      'uom_id': 2,
      'inventory_brand_id': 3,
      'category_id': 4,
      'default_tax_category_id': 5,
      'sales_gl_ledger_id': 10,
      'default_purchase_ledger_id': 11,
      'default_sales_return_ledger_id': 12,
      'default_purchase_return_ledger_id': 13,
      'Price': 19.5,
      'base_price': '18.00',
      'standard_cost': 12.25,
      'Vat_Rate': 5,
      'Opening_Stock': 100,
      'Reorder_Level': 10,
      'is_purchase_item': true,
      'is_sales_item': true,
      'is_stock_item': true,
      'is_serialized': false,
      'is_batch_tracked': true,
      'is_service': false,
      'is_perishable': false,
      'is_active': true,
    });

    expect(dto.id, 12);
    expect(dto.itemName, 'Widget A');
    expect(dto.itemCode, 'W-001');
    expect(dto.itemAlias, 'WA');
    expect(dto.inventoryGroupId, 8);
    expect(dto.legacyGroupKey, 'G-FG');
    expect(dto.uomId, 2);
    expect(dto.inventoryBrandId, 3);
    expect(dto.categoryId, 4);
    expect(dto.defaultTaxCategoryId, 5);
    expect(dto.salesGlLedgerId, 10);
    expect(dto.price, '19.5');
    expect(dto.basePrice, '18.00');
    expect(dto.isBatchTracked, isTrue);
  });

  test('InventoryItemMapper.toEntity uses Decimal for money fields', () {
    const dto = InventoryItemDto(
      id: 1,
      itemName: 'Widget',
      itemCode: 'W1',
      price: '19.50',
      basePrice: '18',
      standardCost: '12.25',
      vatRate: '5',
      openingStock: '100',
      reorderLevel: '10',
      uomId: 2,
    );
    final entity = mapper.toEntity(dto);

    expect(entity.name, 'Widget');
    expect(entity.code, 'W1');
    expect(entity.price, Decimal.parse('19.50'));
    expect(entity.basePrice, Decimal.parse('18'));
    expect(entity.standardCost, Decimal.parse('12.25'));
    expect(entity.uomId, 2);
  });

  test('InventoryItemDto.toJson sends Group_Id from legacy key / group id', () {
    final item = InventoryItem(
      id: 1,
      name: 'Widget A',
      code: 'W-001',
      inventoryGroupId: 8,
      legacyGroupKey: 'G-FG',
      brandId: 3,
      price: Decimal.parse('19.5'),
      basePrice: Decimal.parse('18'),
      standardCost: Decimal.parse('12.25'),
      vatRate: Decimal.parse('5'),
      openingStock: Decimal.parse('100'),
      reorderLevel: Decimal.parse('10'),
      isSalesItem: true,
      isBatchTracked: true,
    );
    final json = mapper.toDto(item).toJson();

    expect(json['Item_Name'], 'Widget A');
    expect(json['Item_Code'], 'W-001');
    expect(json['Group_Id'], 'G-FG');
    expect(json['inventory_group_id'], 8);
    expect(json['inventory_brand_id'], 3);
    expect(json['Price'], 19.5);
    expect(json['base_price'], 18);
    expect(json['is_batch_tracked'], isTrue);
    expect(json.containsKey('id'), isFalse);
  });

  test('round-trip toEntity(toDto(x)) is identity', () {
    final item = InventoryItem(
      id: 4,
      name: 'Service fee',
      code: 'SVC-1',
      price: Decimal.parse('50'),
      basePrice: Decimal.zero,
      standardCost: Decimal.zero,
      vatRate: Decimal.parse('5'),
      openingStock: Decimal.zero,
      reorderLevel: Decimal.zero,
      isService: true,
      isStockItem: false,
      isPurchaseItem: false,
    );
    expect(mapper.toEntity(mapper.toDto(item)), item);
  });
}
