import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/inventory_uom_conversion/data/uom_conversion_dto.dart';
import 'package:algo_erp_front/features/inventory_uom_conversion/domain/uom_conversion.dart';

class UomConversionMapper implements Mapper<UomConversionDto, UomConversion> {
  const UomConversionMapper();

  @override
  UomConversion toEntity(UomConversionDto dto) => UomConversion(
        id: dto.id,
        baseUnit: dto.baseUnit,
        toUnit: dto.toUnit,
        conversionValue: dto.conValue,
        itemId: dto.itemId,
        narration: dto.narration,
      );

  @override
  UomConversionDto toDto(UomConversion entity) => UomConversionDto(
        id: entity.id,
        baseUnit: entity.baseUnit,
        toUnit: entity.toUnit,
        conValue: entity.conversionValue,
        itemId: entity.itemId,
        narration: entity.narration,
      );
}
