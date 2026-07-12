import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/inventory_tax_category/data/tax_category_dto.dart';
import 'package:algo_erp_front/features/inventory_tax_category/domain/tax_category.dart';

class TaxCategoryMapper implements Mapper<TaxCategoryDto, TaxCategory> {
  const TaxCategoryMapper();

  @override
  TaxCategory toEntity(TaxCategoryDto dto) => TaxCategory(
    id: dto.id,
    name: dto.taxName,
    rate: dto.taxRate,
    isActive: dto.isActive,
  );

  @override
  TaxCategoryDto toDto(TaxCategory entity) => TaxCategoryDto(
    id: entity.id,
    taxName: entity.name,
    taxRate: entity.rate,
    isActive: entity.isActive,
  );
}
