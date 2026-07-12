import 'package:equatable/equatable.dart';

const _unset = Object();

/// The Category master entity — hard-deleted (no `is_active` column on the
/// backend `category` table).
class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    this.code,
    this.description,
  });

  final int id;
  final String name;
  final String? code;
  final String? description;

  Category copyWith({
    int? id,
    String? name,
    Object? code = _unset,
    Object? description = _unset,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    code: identical(code, _unset) ? this.code : code as String?,
    description: identical(description, _unset)
        ? this.description
        : description as String?,
  );

  @override
  List<Object?> get props => [id, name, code, description];
}
