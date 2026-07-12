import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/inventory_pricelist/data/price_list_dto.dart';
import 'package:algo_erp_front/features/inventory_pricelist/domain/price_list.dart';

class PriceListMapper implements Mapper<PriceListDto, PriceList> {
  const PriceListMapper();

  @override
  PriceList toEntity(PriceListDto dto) => PriceList(
    id: dto.id,
    name: dto.priceListName,
    startDate: dto.startDate,
    endDate: dto.endDate,
    isDefault: dto.isDefault,
    showInPos: dto.showInPos,
    isOnline: dto.isOnline,
  );

  @override
  PriceListDto toDto(PriceList entity) => PriceListDto(
    id: entity.id,
    priceListName: entity.name,
    startDate: entity.startDate,
    endDate: entity.endDate,
    isDefault: entity.isDefault,
    showInPos: entity.showInPos,
    isOnline: entity.isOnline,
  );
}
