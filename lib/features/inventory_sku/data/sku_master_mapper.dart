import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/inventory_sku/data/sku_master_dto.dart';
import 'package:algo_erp_front/features/inventory_sku/domain/sku_master.dart';
import 'package:decimal/decimal.dart';

class SkuMasterMapper implements Mapper<SkuMasterDto, SkuMaster> {
  const SkuMasterMapper();

  @override
  SkuMaster toEntity(SkuMasterDto dto) => SkuMaster(
    id: dto.id,
    itemId: dto.itemId,
    code: dto.skuCode,
    inventoryItemId: dto.inventoryItemId,
    name: dto.skuName,
    barcode: dto.barcode,
    rate: dto.rate == null ? null : Decimal.tryParse(dto.rate!),
    description: dto.skuDescription,
    skuType: dto.skuType,
    possibleValues: dto.skuPossibleValues,
    value: dto.skuValue,
  );

  @override
  SkuMasterDto toDto(SkuMaster entity) => SkuMasterDto(
    id: entity.id,
    itemId: entity.itemId,
    skuCode: entity.code,
    inventoryItemId: entity.inventoryItemId,
    skuName: entity.name,
    barcode: entity.barcode,
    rate: entity.rate?.toString(),
    skuDescription: entity.description,
    skuType: entity.skuType,
    skuPossibleValues: entity.possibleValues,
    skuValue: entity.value,
  );
}
