import 'package:equatable/equatable.dart';

const _unset = Object();

/// The UserRole master entity — hard-deleted (`UserRoleRepository` sets
/// `softDeleteField: null`; the `user_roles` table has no `is_active` column).
class UserRole extends Equatable {
  const UserRole({required this.id, required this.name, this.description});

  final int id;
  final String name;
  final String? description;

  UserRole copyWith({int? id, String? name, Object? description = _unset}) =>
      UserRole(
        id: id ?? this.id,
        name: name ?? this.name,
        description: identical(description, _unset)
            ? this.description
            : description as String?,
      );

  @override
  List<Object?> get props => [id, name, description];
}
