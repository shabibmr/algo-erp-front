import 'package:algo_erp_front/features/inventory_uom_conversion/data/uom_conversion_dto.dart';
import 'package:algo_erp_front/features/inventory_uom_conversion/data/uom_conversion_mapper.dart';
import 'package:algo_erp_front/features/inventory_uom_conversion/domain/uom_conversion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = UomConversionMapper();

  test("UomConversionDto.fromJson reads the backend's exact wire casing", () {
    final dto = UomConversionDto.fromJson(const {
      'id': 1,
      'baseUnit': 'Kilogram',
      'toUnit': 'Gram',
      'conValue': '1000',
      'itemID': 'ITEM1',
      'narration': 'Standard conversion',
    });

    expect(dto.id, 1);
    expect(dto.baseUnit, 'Kilogram');
    expect(dto.toUnit, 'Gram');
    expect(dto.conValue, '1000');
    expect(dto.itemId, 'ITEM1');
    expect(dto.narration, 'Standard conversion');
  });

  test('UomConversionMapper.toEntity keeps conValue as a String (non-numeric '
      'DB column)', () {
    const dto = UomConversionDto(
      id: 1,
      baseUnit: 'Kilogram',
      toUnit: 'Gram',
      conValue: '1000',
    );
    expect(
      mapper.toEntity(dto),
      const UomConversion(
        id: 1,
        baseUnit: 'Kilogram',
        toUnit: 'Gram',
        conversionValue: '1000',
      ),
    );
  });

  test('UomConversionMapper.toDto round-trips back to the wire shape', () {
    const conversion = UomConversion(
      id: 1,
      baseUnit: 'Kilogram',
      toUnit: 'Gram',
      conversionValue: '1000',
    );
    final dto = mapper.toDto(conversion);

    expect(dto.toJson(), {
      'baseUnit': 'Kilogram',
      'toUnit': 'Gram',
      'conValue': '1000',
      'itemID': null,
      'narration': null,
    });
  });

  test('round-trip toEntity(toDto(x)) is identity', () {
    const conversion = UomConversion(
      id: 5,
      baseUnit: 'Litre',
      toUnit: 'Millilitre',
      conversionValue: '1000',
      itemId: 'ITEM5',
    );
    expect(mapper.toEntity(mapper.toDto(conversion)), conversion);
  });
}
