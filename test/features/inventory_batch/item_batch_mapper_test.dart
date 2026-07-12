import 'package:algo_erp_front/features/inventory_batch/data/item_batch_dto.dart';
import 'package:algo_erp_front/features/inventory_batch/data/item_batch_mapper.dart';
import 'package:algo_erp_front/features/inventory_batch/domain/item_batch.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = ItemBatchMapper();

  test("ItemBatchDto.fromJson reads the backend's wire casing", () {
    final dto = ItemBatchDto.fromJson(const {
      'id': 7,
      'item_id': 12,
      'batch_number': 'B-2025-01',
      'manufacturing_date': '2025-01-15',
      'expiration_date': '2026-01-15',
      'cost_price': '3.5000',
      'selling_price': 5.25,
      'is_active': true,
    });

    expect(dto.id, 7);
    expect(dto.itemId, 12);
    expect(dto.batchNumber, 'B-2025-01');
    expect(dto.manufacturingDate, DateTime(2025, 1, 15));
    expect(dto.expirationDate, DateTime(2026, 1, 15));
    expect(dto.costPrice, '3.5000');
    expect(dto.sellingPrice, '5.25');
  });

  test('ItemBatchMapper.toEntity uses Decimal for prices', () {
    const dto = ItemBatchDto(
      id: 1,
      itemId: 2,
      batchNumber: 'B1',
      costPrice: '3.5',
      sellingPrice: '5.25',
    );
    final entity = mapper.toEntity(dto);
    expect(entity.costPrice, Decimal.parse('3.5'));
    expect(entity.sellingPrice, Decimal.parse('5.25'));
  });

  test('ItemBatchDto.toJson formats dates as YYYY-MM-DD', () {
    final batch = ItemBatch(
      id: 1,
      itemId: 12,
      batchNumber: 'B-1',
      manufacturingDate: DateTime(2025, 1, 15),
      expirationDate: DateTime(2026, 1, 15),
      costPrice: Decimal.parse('3.5'),
      sellingPrice: Decimal.parse('5.25'),
    );
    final json = mapper.toDto(batch).toJson();

    expect(json['item_id'], 12);
    expect(json['batch_number'], 'B-1');
    expect(json['manufacturing_date'], '2025-01-15');
    expect(json['expiration_date'], '2026-01-15');
    expect(json['cost_price'], 3.5);
    expect(json['selling_price'], 5.25);
    expect(json.containsKey('id'), isFalse);
  });

  test('round-trip toEntity(toDto(x)) is identity', () {
    final batch = ItemBatch(
      id: 4,
      itemId: 9,
      batchNumber: 'LOT-A',
      costPrice: Decimal.zero,
      sellingPrice: Decimal.parse('10'),
      isActive: true,
    );
    expect(mapper.toEntity(mapper.toDto(batch)), batch);
  });
}
