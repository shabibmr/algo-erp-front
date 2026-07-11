import 'package:algo_erp_front/features/inventory_tax_category/data/tax_category_dto.dart';
import 'package:algo_erp_front/features/inventory_tax_category/data/tax_category_mapper.dart';
import 'package:algo_erp_front/features/inventory_tax_category/domain/tax_category.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = TaxCategoryMapper();

  test("TaxCategoryDto.fromJson reads the backend's exact wire casing", () {
    final dto = TaxCategoryDto.fromJson(const {
      'id': 1,
      'tax_name': 'VAT',
      'tax_rate': '5.00',
      'is_active': true,
    });

    expect(dto.id, 1);
    expect(dto.taxName, 'VAT');
    expect(dto.taxRate, Decimal.parse('5.00'));
    expect(dto.isActive, isTrue);
  });

  test('TaxCategoryDto.fromJson defaults isActive to true when absent', () {
    final dto = TaxCategoryDto.fromJson(const {
      'id': 2,
      'tax_name': 'Zero-rated',
      'tax_rate': 0,
    });
    expect(dto.isActive, isTrue);
  });

  test('TaxCategoryMapper.toEntity produces a clean-named TaxCategory', () {
    final dto = TaxCategoryDto(
      id: 1,
      taxName: 'VAT',
      taxRate: Decimal.parse('5.00'),
      isActive: true,
    );
    expect(
      mapper.toEntity(dto),
      TaxCategory(id: 1, name: 'VAT', rate: Decimal.parse('5.00')),
    );
  });

  test('TaxCategoryMapper.toDto round-trips back to the wire shape', () {
    final taxCategory =
        TaxCategory(id: 1, name: 'VAT', rate: Decimal.parse('5.00'));
    final dto = mapper.toDto(taxCategory);

    expect(dto.toJson(), {
      'tax_name': 'VAT',
      'tax_rate': 5.0,
      'is_active': true,
    });
  });

  test('round-trip toEntity(toDto(x)) is identity', () {
    final taxCategory = TaxCategory(
      id: 5,
      name: 'Exempt',
      rate: Decimal.zero,
      isActive: false,
    );
    expect(mapper.toEntity(mapper.toDto(taxCategory)), taxCategory);
  });
}
