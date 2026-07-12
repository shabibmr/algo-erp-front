import 'package:algo_erp_front/features/inventory_godown/data/godown_dto.dart';
import 'package:algo_erp_front/features/inventory_godown/data/godown_mapper.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = GodownMapper();

  test("GodownDto.fromJson reads the backend's exact wire casing", () {
    final dto = GodownDto.fromJson(const {
      'id': 1,
      'Godown_Name': 'Main store',
      'godown_code': 'MAIN',
      'Godown_Location': 'Dubai',
      'is_profit_centre': true,
      'is_default': true,
      'is_production': false,
    });

    expect(dto.id, 1);
    expect(dto.godownName, 'Main store');
    expect(dto.godownCode, 'MAIN');
    expect(dto.godownLocation, 'Dubai');
    expect(dto.isProfitCentre, isTrue);
    expect(dto.isDefault, isTrue);
    expect(dto.isProduction, isFalse);
  });

  test('GodownDto.fromJson defaults bool flags to false when absent', () {
    final dto = GodownDto.fromJson(const {'id': 2, 'Godown_Name': 'Sub'});
    expect(dto.isProfitCentre, isFalse);
    expect(dto.isDefault, isFalse);
    expect(dto.isProduction, isFalse);
  });

  test('GodownMapper.toEntity produces a clean-named Godown', () {
    const dto = GodownDto(
      id: 1,
      godownName: 'Main store',
      godownCode: 'MAIN',
      isDefault: true,
    );
    expect(
      mapper.toEntity(dto),
      const Godown(id: 1, name: 'Main store', code: 'MAIN', isDefault: true),
    );
  });

  test('GodownMapper.toDto round-trips back to the wire shape', () {
    const godown = Godown(
      id: 1,
      name: 'Main store',
      code: 'MAIN',
      isDefault: true,
    );
    final dto = mapper.toDto(godown);

    expect(dto.toJson(), {
      'Godown_Name': 'Main store',
      'godown_code': 'MAIN',
      'Godown_Location': null,
      'Godown_Narration': null,
      'is_profit_centre': false,
      'is_default': true,
      'is_production': false,
    });
  });

  test('round-trip toEntity(toDto(x)) is identity', () {
    const godown = Godown(
      id: 5,
      name: 'Cold store',
      code: 'COLD',
      isProduction: true,
    );
    expect(mapper.toEntity(mapper.toDto(godown)), godown);
  });
}
