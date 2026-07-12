import 'package:algo_erp_front/features/inventory_route/data/route_master_dto.dart';
import 'package:algo_erp_front/features/inventory_route/data/route_master_mapper.dart';
import 'package:algo_erp_front/features/inventory_route/domain/route_master.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = RouteMasterMapper();

  test("RouteMasterDto.fromJson reads the backend's exact wire casing", () {
    final dto = RouteMasterDto.fromJson(const {
      'id': 1,
      'route_id': 'R001',
      'route_name': 'North route',
      'Description': 'Covers north zone',
    });

    expect(dto.id, 1);
    expect(dto.routeId, 'R001');
    expect(dto.routeName, 'North route');
    expect(dto.description, 'Covers north zone');
  });

  test('RouteMasterMapper.toEntity produces a clean-named RouteMaster', () {
    const dto = RouteMasterDto(
      id: 1,
      routeId: 'R001',
      routeName: 'North route',
    );
    expect(
      mapper.toEntity(dto),
      const RouteMaster(id: 1, routeCode: 'R001', name: 'North route'),
    );
  });

  test('RouteMasterMapper.toDto round-trips back to the wire shape', () {
    const route = RouteMaster(id: 1, routeCode: 'R001', name: 'North route');
    final dto = mapper.toDto(route);

    expect(dto.toJson(), {
      'route_id': 'R001',
      'route_name': 'North route',
      'Description': null,
    });
  });

  test('round-trip toEntity(toDto(x)) is identity', () {
    const route = RouteMaster(
      id: 5,
      routeCode: 'R005',
      name: 'South route',
      description: 'Covers south zone',
    );
    expect(mapper.toEntity(mapper.toDto(route)), route);
  });
}
