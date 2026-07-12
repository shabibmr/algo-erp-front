import 'package:equatable/equatable.dart';

/// The Department master entity. The backend's `department` table also has
/// a self-referencing `parent_dept_id` (a tree of departments) — deliberately
/// **not** exposed here: `FieldType.selfFk` and its tree-picker widget don't
/// exist yet (see `docs/manifest-spec.md`), so this manifest only covers
/// Department's flat fields. Revisit once a tree-picker widget lands.
class Department extends Equatable {
  const Department({
    required this.id,
    required this.code,
    required this.name,
    this.isActive = true,
  });

  final int id;
  final String code;
  final String name;
  final bool isActive;

  Department copyWith({int? id, String? code, String? name, bool? isActive}) =>
      Department(
        id: id ?? this.id,
        code: code ?? this.code,
        name: name ?? this.name,
        isActive: isActive ?? this.isActive,
      );

  @override
  List<Object?> get props => [id, code, name, isActive];
}
