import 'package:algo_erp_front/features/inventory_uom/data/uom_dto.dart';
import 'package:algo_erp_front/features/inventory_uom/data/uom_mapper.dart';
import 'package:algo_erp_front/features/inventory_uom/domain/uom.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = UomMapper();

  test("UomDto.fromJson reads the backend's exact wire casing", () {
    final dto = UomDto.fromJson(const {
      'id': 1,
      'uom_Name': 'Kilogram',
      'uom_code': 'KG',
      'decimal_places': 3,
      'uom_symbol': 'kg',
      'is_Composite': false,
    });

    expect(dto.id, 1);
    expect(dto.uomName, 'Kilogram');
    expect(dto.uomCode, 'KG');
    expect(dto.decimalPlaces, 3);
    expect(dto.uomSymbol, 'kg');
    expect(dto.isComposite, isFalse);
  });

  test('UomDto.fromJson defaults decimalPlaces/isComposite when absent', () {
    final dto = UomDto.fromJson(const {'id': 2, 'uom_Name': 'Piece'});
    expect(dto.decimalPlaces, 0);
    expect(dto.isComposite, isFalse);
  });

  test('UomMapper.toEntity produces a clean-named Uom', () {
    const dto = UomDto(
      id: 1,
      uomName: 'Kilogram',
      uomCode: 'KG',
      decimalPlaces: 3,
      uomSymbol: 'kg',
    );
    expect(
      mapper.toEntity(dto),
      const Uom(
        id: 1,
        name: 'Kilogram',
        code: 'KG',
        decimalPlaces: 3,
        symbol: 'kg',
      ),
    );
  });

  test('UomMapper.toDto round-trips back to the wire shape', () {
    const uom = Uom(id: 1, name: 'Kilogram', code: 'KG', decimalPlaces: 3);
    final dto = mapper.toDto(uom);

    expect(dto.toJson(), {
      'uom_Name': 'Kilogram',
      'uom_code': 'KG',
      'decimal_places': 3,
      'uom_symbol': null,
      'is_Composite': false,
    });
  });

  test('round-trip toEntity(toDto(x)) is identity', () {
    const uom = Uom(id: 5, name: 'Litre', code: 'L', decimalPlaces: 2);
    expect(mapper.toEntity(mapper.toDto(uom)), uom);
  });
}
