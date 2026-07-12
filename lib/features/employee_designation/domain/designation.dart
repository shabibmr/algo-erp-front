import 'package:equatable/equatable.dart';

/// The Designation master entity. Stores only the raw `departmentId`
/// foreign-key id — the backend doesn't embed the related `Department` row
/// on this endpoint, so the entity mirrors that (no embedded object).
class Designation extends Equatable {
  const Designation({
    required this.id,
    required this.code,
    required this.name,
    required this.departmentId,
    this.isActive = true,
  });

  final int id;
  final String code;
  final String name;
  final int departmentId;
  final bool isActive;

  Designation copyWith({
    int? id,
    String? code,
    String? name,
    int? departmentId,
    bool? isActive,
  }) => Designation(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    departmentId: departmentId ?? this.departmentId,
    isActive: isActive ?? this.isActive,
  );

  @override
  List<Object?> get props => [id, code, name, departmentId, isActive];
}
