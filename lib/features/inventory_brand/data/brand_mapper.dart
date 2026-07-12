import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/inventory_brand/data/brand_dto.dart';
import 'package:algo_erp_front/features/inventory_brand/domain/brand.dart';

class BrandMapper implements Mapper<BrandDto, Brand> {
  const BrandMapper();

  @override
  Brand toEntity(BrandDto dto) =>
      Brand(id: dto.id, name: dto.brandName, description: dto.brandDescription);

  @override
  BrandDto toDto(Brand entity) => BrandDto(
    id: entity.id,
    brandName: entity.name,
    brandDescription: entity.description,
  );
}
