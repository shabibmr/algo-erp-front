import 'package:algo_erp_front/features/inventory_sku/data/sku_master_dto.dart';
import 'package:algo_erp_front/features/inventory_sku/data/sku_master_mapper.dart';
import 'package:algo_erp_front/features/inventory_sku/domain/sku_master.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = SkuMasterMapper();

  test("SkuMasterDto.fromJson reads the backend's wire casing", () {
    final dto = SkuMasterDto.fromJson(const {
      'id': 5,
      'sku_code': 'SKU-1',
      'inventory_item_id': 12,
      'ITEM_ID': 'W-001',
      'sku_name': 'Red variant',
      'barcode': '123456',
      'rate': '9.50',
      'SKU_DESCRIPTION': 'Color red',
      'SKU_TYPE': 1,
      'SKU_POSSIBLE_VALUES': 'red,blue',
      'SKU_VALUE': 'red',
    });

    expect(dto.id, 5);
    expect(dto.skuCode, 'SKU-1');
    expect(dto.inventoryItemId, 12);
    expect(dto.itemId, 'W-001');
    expect(dto.rate, '9.50');
    expect(dto.skuType, 1);
  });

  test('SkuMasterMapper.toEntity uses Decimal for rate', () {
    const dto = SkuMasterDto(id: 1, itemId: 'X', rate: '12.25', skuType: 2);
    final entity = mapper.toEntity(dto);
    expect(entity.rate, Decimal.parse('12.25'));
    expect(entity.skuType, 2);
  });

  test('SkuMasterDto.toJson omits id and sends rate as number', () {
    final sku = SkuMaster(
      id: 1,
      itemId: 'W-001',
      code: 'SKU-1',
      inventoryItemId: 12,
      name: 'Red',
      rate: Decimal.parse('9.5'),
      skuType: 1,
    );
    final json = mapper.toDto(sku).toJson();

    expect(json['ITEM_ID'], 'W-001');
    expect(json['sku_code'], 'SKU-1');
    expect(json['inventory_item_id'], 12);
    expect(json['rate'], 9.5);
    expect(json['SKU_TYPE'], 1);
    expect(json.containsKey('id'), isFalse);
  });

  test('round-trip toEntity(toDto(x)) is identity', () {
    final sku = SkuMaster(
      id: 3,
      itemId: 'I1',
      code: 'S1',
      name: 'Bundle',
      rate: Decimal.parse('1'),
      skuType: 2,
    );
    expect(mapper.toEntity(mapper.toDto(sku)), sku);
  });
}
