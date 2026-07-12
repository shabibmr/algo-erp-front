import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/inventory_category/data/category_dto.dart';
import 'package:algo_erp_front/features/inventory_category/domain/category.dart';

class CategoryMapper implements Mapper<CategoryDto, Category> {
  const CategoryMapper();

  @override
  Category toEntity(CategoryDto dto) => Category(
    id: dto.id,
    name: dto.categoryName,
    code: dto.categoryCode,
    description: dto.description,
  );

  @override
  CategoryDto toDto(Category entity) => CategoryDto(
    id: entity.id,
    categoryName: entity.name,
    categoryCode: entity.code,
    description: entity.description,
  );
}
