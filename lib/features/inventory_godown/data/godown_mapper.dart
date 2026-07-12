import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/inventory_godown/data/godown_dto.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';

class GodownMapper implements Mapper<GodownDto, Godown> {
  const GodownMapper();

  @override
  Godown toEntity(GodownDto dto) => Godown(
    id: dto.id,
    name: dto.godownName,
    code: dto.godownCode,
    location: dto.godownLocation,
    narration: dto.godownNarration,
    isProfitCentre: dto.isProfitCentre,
    isDefault: dto.isDefault,
    isProduction: dto.isProduction,
  );

  @override
  GodownDto toDto(Godown entity) => GodownDto(
    id: entity.id,
    godownName: entity.name,
    godownCode: entity.code,
    godownLocation: entity.location,
    godownNarration: entity.narration,
    isProfitCentre: entity.isProfitCentre,
    isDefault: entity.isDefault,
    isProduction: entity.isProduction,
  );
}
