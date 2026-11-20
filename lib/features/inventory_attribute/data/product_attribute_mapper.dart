import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/inventory_attribute/data/product_attribute_dto.dart';
import 'package:algo_erp_front/features/inventory_attribute/domain/product_attribute.dart';

class ProductAttributeOptionMapper
    implements Mapper<ProductAttributeOptionDto, ProductAttributeOption> {
  const ProductAttributeOptionMapper();

  @override
  ProductAttributeOption toEntity(ProductAttributeOptionDto dto) =>
      ProductAttributeOption(
        id: dto.id,
        attributeId: dto.attributeId,
        value: dto.attributeValue,
        valueCode: dto.valueCode,
        displayOrder: dto.displayOrder,
        isActive: dto.isActive,
      );

  @override
  ProductAttributeOptionDto toDto(ProductAttributeOption entity) =>
      ProductAttributeOptionDto(
        id: entity.id,
        attributeId: entity.attributeId,
        attributeValue: entity.value,
        valueCode: entity.valueCode,
        displayOrder: entity.displayOrder,
        isActive: entity.isActive,
      );
}

class ProductAttributeMapper
    implements Mapper<ProductAttributeDto, ProductAttribute> {
  const ProductAttributeMapper();

  static const _optMapper = ProductAttributeOptionMapper();

  @override
  ProductAttribute toEntity(ProductAttributeDto dto) => ProductAttribute(
    id: dto.id,
    name: dto.attributeName,
    code: dto.attributeCode,
    type: AttributeType.fromWire(dto.attributeType),
    dataType: dto.dataType,
    parentId: dto.parentId,
    parentName: dto.parentName,
    unit: dto.unit,
    isActive: dto.isActive,
    options: dto.values.map(_optMapper.toEntity).toList(),
    subAttributes: dto.subAttributes.map(toEntity).toList(),
  );

  @override
  ProductAttributeDto toDto(ProductAttribute entity) => ProductAttributeDto(
    id: entity.id,
    attributeName: entity.name,
    attributeCode: entity.code,
    attributeType: entity.type.wireValue,
    dataType: entity.dataType,
    parentId: entity.parentId,
    parentName: entity.parentName,
    unit: entity.unit,
    isActive: entity.isActive,
    values: entity.options.map(_optMapper.toDto).toList(),
    subAttributes: entity.subAttributes.map(toDto).toList(),
  );
}
