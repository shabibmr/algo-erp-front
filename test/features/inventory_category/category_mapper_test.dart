import 'package:algo_erp_front/features/inventory_category/data/category_dto.dart';
import 'package:algo_erp_front/features/inventory_category/data/category_mapper.dart';
import 'package:algo_erp_front/features/inventory_category/domain/category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = CategoryMapper();

  test("CategoryDto.fromJson reads the backend's exact wire casing", () {
    final dto = CategoryDto.fromJson(const {
      'id': 1,
      'category_code': 'ELEC',
      'category_name': 'Electronics',
      'Description': 'Electronic goods',
    });

    expect(dto.id, 1);
    expect(dto.categoryCode, 'ELEC');
    expect(dto.categoryName, 'Electronics');
    expect(dto.description, 'Electronic goods');
  });

  test('CategoryMapper.toEntity produces a clean-named Category', () {
    const dto = CategoryDto(
      id: 1,
      categoryName: 'Electronics',
      categoryCode: 'ELEC',
    );
    expect(
      mapper.toEntity(dto),
      const Category(id: 1, name: 'Electronics', code: 'ELEC'),
    );
  });

  test('CategoryMapper.toDto round-trips back to the wire shape', () {
    const category = Category(id: 1, name: 'Electronics', code: 'ELEC');
    final dto = mapper.toDto(category);

    expect(dto.toJson(), {
      'category_name': 'Electronics',
      'category_code': 'ELEC',
      'Description': null,
    });
  });

  test('round-trip toEntity(toDto(x)) is identity', () {
    const category =
        Category(id: 5, name: 'Groceries', code: 'GRO', description: 'Food');
    expect(mapper.toEntity(mapper.toDto(category)), category);
  });
}
