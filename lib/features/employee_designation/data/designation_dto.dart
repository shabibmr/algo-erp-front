import 'package:equatable/equatable.dart';

/// Wire shape of `/employee/designations`, matching the backend
/// `designation` table (`department_id` is a hard FK to `department`, not a
/// self-FK — see `docs/feature-inventory.md` §4).
class DesignationDto extends Equatable {
  const DesignationDto({
    required this.id,
    required this.designationCode,
    required this.designationName,
    required this.departmentId,
    required this.isActive,
  });

  factory DesignationDto.fromJson(Map<String, dynamic> json) => DesignationDto(
    id: json['id'] as int,
    designationCode: json['designation_code'] as String,
    designationName: json['designation_name'] as String,
    departmentId: json['department_id'] as int,
    isActive: json['is_active'] as bool? ?? true,
  );

  final int id;
  final String designationCode;
  final String designationName;
  final int departmentId;
  final bool isActive;

  Map<String, dynamic> toJson() => {
    'designation_code': designationCode,
    'designation_name': designationName,
    'department_id': departmentId,
    'is_active': isActive,
  };

  @override
  List<Object?> get props => [
    id,
    designationCode,
    designationName,
    departmentId,
    isActive,
  ];
}
