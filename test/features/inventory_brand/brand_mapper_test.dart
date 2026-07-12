import 'package:algo_erp_front/features/inventory_brand/data/brand_dto.dart';
import 'package:algo_erp_front/features/inventory_brand/data/brand_mapper.dart';
import 'package:algo_erp_front/features/inventory_brand/domain/brand.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = BrandMapper();

  test("BrandDto.fromJson reads the backend's exact wire casing", () {
    final dto = BrandDto.fromJson(const {
      'id': 1,
      'Brand_Name': 'Acme',
      'Brand_Description': 'Widgets and gadgets',
    });

    expect(dto.id, 1);
    expect(dto.brandName, 'Acme');
    expect(dto.brandDescription, 'Widgets and gadgets');
  });

  test('BrandDto.fromJson tolerates a null description', () {
    final dto = BrandDto.fromJson(const {'id': 2, 'Brand_Name': 'Acme'});
    expect(dto.brandDescription, isNull);
  });

  test('BrandMapper.toEntity produces a clean-named Brand', () {
    const dto = BrandDto(id: 1, brandName: 'Acme', brandDescription: 'Widgets');
    final brand = mapper.toEntity(dto);

    expect(brand, const Brand(id: 1, name: 'Acme', description: 'Widgets'));
  });

  test('BrandMapper.toDto round-trips back to the wire shape', () {
    const brand = Brand(id: 1, name: 'Acme', description: 'Widgets');
    final dto = mapper.toDto(brand);

    expect(dto.toJson(), {
      'Brand_Name': 'Acme',
      'Brand_Description': 'Widgets',
    });
  });

  test('round-trip toEntity(toDto(x)) is identity', () {
    const brand = Brand(id: 5, name: 'Zenith');
    expect(mapper.toEntity(mapper.toDto(brand)), brand);
  });
}
