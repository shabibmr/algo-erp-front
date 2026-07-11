import 'package:algo_erp_front/features/inventory_item_property/data/item_property_dto.dart';
import 'package:algo_erp_front/features/inventory_item_property/data/item_property_mapper.dart';
import 'package:algo_erp_front/features/inventory_item_property/domain/item_property.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = ItemPropertyMapper();

  test("ItemPropertyDto.fromJson reads the backend's exact wire casing", () {
    final dto = ItemPropertyDto.fromJson(const {
      'id': 1,
      'Property_ID': 'COLOR',
      'Item_ID': 'ITEM-001',
      'Default_Value': 'Red',
    });

    expect(dto.id, 1);
    expect(dto.propertyId, 'COLOR');
    expect(dto.itemId, 'ITEM-001');
    expect(dto.defaultValue, 'Red');
  });

  test('ItemPropertyDto.fromJson tolerates a null Default_Value', () {
    final dto = ItemPropertyDto.fromJson(const {
      'id': 1,
      'Property_ID': 'SIZE',
      'Item_ID': 'ITEM-002',
      'Default_Value': null,
    });

    expect(dto.defaultValue, isNull);
  });

  test('ItemPropertyMapper.toEntity maps dto fields to entity fields', () {
    const dto = ItemPropertyDto(
      id: 1,
      propertyId: 'COLOR',
      itemId: 'ITEM-001',
      defaultValue: 'Red',
    );

    expect(
      mapper.toEntity(dto),
      const ItemProperty(
        id: 1,
        propertyId: 'COLOR',
        itemId: 'ITEM-001',
        defaultValue: 'Red',
      ),
    );
  });

  test('ItemPropertyMapper.toDto round-trips back to the wire shape', () {
    const property = ItemProperty(
      id: 1,
      propertyId: 'COLOR',
      itemId: 'ITEM-001',
      defaultValue: 'Red',
    );

    expect(mapper.toDto(property).toJson(), {
      'Property_ID': 'COLOR',
      'Item_ID': 'ITEM-001',
      'Default_Value': 'Red',
    });
  });

  test('round-trip toEntity(toDto(x)) is identity', () {
    const property = ItemProperty(
      id: 5,
      propertyId: 'SIZE',
      itemId: 'ITEM-003',
    );
    expect(mapper.toEntity(mapper.toDto(property)), property);
  });
}
