import 'package:equatable/equatable.dart';

const _unset = Object();

/// The RouteMaster entity — hard-deleted (no `is_active` column on the
/// backend `route_master` table). Named `RouteMaster` (not `Route`) to
/// avoid colliding with `go_router`'s own `Route` type.
class RouteMaster extends Equatable {
  const RouteMaster({
    required this.id,
    required this.routeCode,
    this.name,
    this.description,
  });

  final int id;

  /// The backend's business-code string PK-adjacent field (`route_id`) —
  /// not the row's `id`, which is the real database PK.
  final String routeCode;
  final String? name;
  final String? description;

  RouteMaster copyWith({
    int? id,
    String? routeCode,
    Object? name = _unset,
    Object? description = _unset,
  }) =>
      RouteMaster(
        id: id ?? this.id,
        routeCode: routeCode ?? this.routeCode,
        name: identical(name, _unset) ? this.name : name as String?,
        description: identical(description, _unset)
            ? this.description
            : description as String?,
      );

  @override
  List<Object?> get props => [id, routeCode, name, description];
}
