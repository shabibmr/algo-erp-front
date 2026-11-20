import 'package:decimal/decimal.dart';
import 'package:algo_erp_front/features/inventory_attribute/data/product_attribute_dto.dart';
import 'package:algo_erp_front/features/inventory_attribute/data/product_attribute_mapper.dart';
import 'package:algo_erp_front/features/inventory_attribute/domain/product_attribute.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = ProductAttributeMapper();

  test('maps a child attribute with its parent name', () {
    final attr = mapper.toEntity(
      ProductAttributeDto.fromJson(const {
        'id': 11,
        'attribute_name': 'Neck',
        'attribute_type': 'EDITABLE',
        'parent_id': 4,
        'parent_attribute': {'id': 4, 'attribute_name': 'Shirt Measurements'},
        'unit': 'inches',
      }),
    );

    expect(attr.parentId, 4);
    expect(attr.parentName, 'Shirt Measurements');
    expect(attr.isEditable, isTrue);
  });

  test('maps a predetermined attribute with its options', () {
    final attr = mapper.toEntity(
      ProductAttributeDto.fromJson(const {
        'id': 1,
        'attribute_name': 'Size',
        'attribute_type': 'PREDETERMINED',
        'values': [
          {
            'id': 7,
            'attribute_id': 1,
            'attribute_value': 'L',
            'value_code': 'LG',
            'display_order': 2,
          },
        ],
      }),
    );

    expect(attr.isPredetermined, isTrue);
    expect(attr.options.single.id, 7);
    expect(attr.options.single.value, 'L');
    expect(attr.options.single.valueCode, 'LG');
  });

  test('maps a group with sub-attributes', () {
    final attr = mapper.toEntity(
      ProductAttributeDto.fromJson(const {
        'id': 4,
        'attribute_name': 'Shirt Measurements',
        'attribute_type': 'GROUP',
        'sub_attributes': [
          {
            'id': 11,
            'attribute_name': 'Neck',
            'attribute_type': 'EDITABLE',
            'parent_id': 4,
          },
        ],
      }),
    );

    expect(attr.isGroup, isTrue);
    expect(attr.subAttributes.single.name, 'Neck');
  });

  test('maps an item assignment with its flags', () {
    final a = mapAssignment(
      ItemAttributeAssignmentDto.fromJson(const {
        'attribute_id': 1,
        'is_required': true,
        'display_order': 3,
        'attribute': {
          'id': 1,
          'attribute_name': 'Size',
          'attribute_type': 'PREDETERMINED',
        },
      }),
    );

    expect(a.isRequired, isTrue);
    expect(a.displayOrder, 3);
    expect(a.attribute.name, 'Size');
  });

  test('maps the resolve envelope with a string decimal rate', () {
    final r = mapResolvedVariant(
      ResolvedVariantDto.fromJson(const {
        'isNew': true,
        'sku': {
          'id': 9,
          'sku_code': 'OX-L',
          'sku_name': 'Oxford (Size: L)',
          'attribute_summary': 'Size: L',
          'rate': '45.00',
        },
      }),
    );

    expect(r.isNew, isTrue);
    expect(r.sku.id, 9);
    expect(r.sku.attributeSummary, 'Size: L');
    expect(r.sku.rate, Decimal.parse('45'));
  });
}
