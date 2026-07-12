import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/inventory_item_property/data/item_property_dto.dart';
import 'package:algo_erp_front/features/inventory_item_property/domain/item_property.dart';

class ItemPropertyMapper implements Mapper<ItemPropertyDto, ItemProperty> {
  const ItemPropertyMapper();

  @override
  ItemProperty toEntity(ItemPropertyDto dto) => ItemProperty(
    id: dto.id,
    propertyId: dto.propertyId,
    itemId: dto.itemId,
    defaultValue: dto.defaultValue,
  );

  @override
  ItemPropertyDto toDto(ItemProperty entity) => ItemPropertyDto(
    id: entity.id,
    propertyId: entity.propertyId,
    itemId: entity.itemId,
    defaultValue: entity.defaultValue,
  );
}
