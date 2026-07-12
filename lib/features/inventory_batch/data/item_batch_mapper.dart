import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/inventory_batch/data/item_batch_dto.dart';
import 'package:algo_erp_front/features/inventory_batch/domain/item_batch.dart';
import 'package:decimal/decimal.dart';

class ItemBatchMapper implements Mapper<ItemBatchDto, ItemBatch> {
  const ItemBatchMapper();

  static Decimal _d(String raw) => Decimal.tryParse(raw) ?? Decimal.zero;

  @override
  ItemBatch toEntity(ItemBatchDto dto) => ItemBatch(
    id: dto.id,
    itemId: dto.itemId,
    batchNumber: dto.batchNumber,
    manufacturingDate: dto.manufacturingDate,
    expirationDate: dto.expirationDate,
    costPrice: _d(dto.costPrice),
    sellingPrice: _d(dto.sellingPrice),
    isActive: dto.isActive,
  );

  @override
  ItemBatchDto toDto(ItemBatch entity) => ItemBatchDto(
    id: entity.id,
    itemId: entity.itemId,
    batchNumber: entity.batchNumber,
    manufacturingDate: entity.manufacturingDate,
    expirationDate: entity.expirationDate,
    costPrice: entity.costPrice.toString(),
    sellingPrice: entity.sellingPrice.toString(),
    isActive: entity.isActive,
  );
}
