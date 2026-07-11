import 'package:equatable/equatable.dart';

const _unset = Object();

/// The Brand master entity — hard-deleted (no `is_active` column on the
/// backend `brands` table), so `Repository.delete` simply removes the row.
class Brand extends Equatable {
  const Brand({
    required this.id,
    required this.name,
    this.description,
  });

  final int id;
  final String name;
  final String? description;

  /// [description] uses a sentinel default (rather than `??`) so passing
  /// `description: null` actually clears a previously-set value — `??` can
  /// never null out a field, which matters once a form needs to clear it.
  Brand copyWith({int? id, String? name, Object? description = _unset}) =>
      Brand(
        id: id ?? this.id,
        name: name ?? this.name,
        description: identical(description, _unset)
            ? this.description
            : description as String?,
      );

  @override
  List<Object?> get props => [id, name, description];
}
