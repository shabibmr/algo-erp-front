import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/inventory_pricelist/data/price_list_entry_dto.dart';
import 'package:algo_erp_front/features/inventory_pricelist/domain/price_list_entry.dart';

class PriceListEntryMapper
    implements Mapper<PriceListEntryDto, PriceListEntry> {
  const PriceListEntryMapper();

  @override
  PriceListEntry toEntity(PriceListEntryDto dto) => PriceListEntry(
    id: dto.id,
    itemId: dto.itemId,
    price: dto.price,
    priceListId: dto.priceListId,
    percent: dto.percent,
    uomId: dto.uomId,
    entryType: dto.entryType,
  );

  @override
  PriceListEntryDto toDto(PriceListEntry entity) => PriceListEntryDto(
    id: entity.id,
    itemId: entity.itemId,
    price: entity.price,
    priceListId: entity.priceListId,
    percent: entity.percent,
    uomId: entity.uomId,
    entryType: entity.entryType,
  );
}
