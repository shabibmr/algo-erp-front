import 'package:equatable/equatable.dart';

/// Wire shape of `/inventory/route`, matching the backend `route_master`
/// table.
class RouteMasterDto extends Equatable {
  const RouteMasterDto({
    required this.id,
    required this.routeId,
    this.routeName,
    this.description,
  });

  factory RouteMasterDto.fromJson(Map<String, dynamic> json) =>
      RouteMasterDto(
        id: json['id'] as int,
        routeId: json['route_id'] as String,
        routeName: json['route_name'] as String?,
        description: json['Description'] as String?,
      );

  final int id;
  final String routeId;
  final String? routeName;
  final String? description;

  Map<String, dynamic> toJson() => {
        'route_id': routeId,
        'route_name': routeName,
        'Description': description,
      };

  @override
  List<Object?> get props => [id, routeId, routeName, description];
}
