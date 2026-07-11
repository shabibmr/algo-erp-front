import 'package:equatable/equatable.dart';

/// Wire shape of `/employee/departments`, matching the backend `department`
/// table. Field names keep the backend's original casing per
/// `feature-contract.md` — the mapper produces clean entity names.
class DepartmentDto extends Equatable {
  const DepartmentDto({
    required this.id,
    required this.deptCode,
    required this.deptName,
    required this.isActive,
  });

  factory DepartmentDto.fromJson(Map<String, dynamic> json) => DepartmentDto(
        id: json['id'] as int,
        deptCode: json['dept_code'] as String,
        deptName: json['dept_name'] as String,
        isActive: json['is_active'] as bool? ?? true,
      );

  final int id;
  final String deptCode;
  final String deptName;
  final bool isActive;

  /// `id`/timestamps/`parent_dept_id` (not exposed by this manifest yet —
  /// see `Department`'s doc comment) are never sent on write.
  Map<String, dynamic> toJson() => {
        'dept_code': deptCode,
        'dept_name': deptName,
        'is_active': isActive,
      };

  @override
  List<Object?> get props => [id, deptCode, deptName, isActive];
}
