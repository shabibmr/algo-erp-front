import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/inventory_uom/data/uom_dto.dart';
import 'package:algo_erp_front/features/inventory_uom/domain/uom.dart';

class UomMapper implements Mapper<UomDto, Uom> {
  const UomMapper();

  @override
  Uom toEntity(UomDto dto) => Uom(
        id: dto.id,
        name: dto.uomName,
        code: dto.uomCode,
        decimalPlaces: dto.decimalPlaces,
        symbol: dto.uomSymbol,
        isComposite: dto.isComposite,
      );

  @override
  UomDto toDto(Uom entity) => UomDto(
        id: entity.id,
        uomName: entity.name,
        uomCode: entity.code,
        decimalPlaces: entity.decimalPlaces,
        uomSymbol: entity.symbol,
        isComposite: entity.isComposite,
      );
}
