import 'package:equatable/equatable.dart';

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

  Brand copyWith({int? id, String? name, String? description}) => Brand(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
      );

  @override
  List<Object?> get props => [id, name, description];
}
