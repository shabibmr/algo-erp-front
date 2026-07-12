import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/inventory_route/data/route_master_dto.dart';
import 'package:algo_erp_front/features/inventory_route/domain/route_master.dart';

class RouteMasterMapper implements Mapper<RouteMasterDto, RouteMaster> {
  const RouteMasterMapper();

  @override
  RouteMaster toEntity(RouteMasterDto dto) => RouteMaster(
    id: dto.id,
    routeCode: dto.routeId,
    name: dto.routeName,
    description: dto.description,
  );

  @override
  RouteMasterDto toDto(RouteMaster entity) => RouteMasterDto(
    id: entity.id,
    routeId: entity.routeCode,
    routeName: entity.name,
    description: entity.description,
  );
}
