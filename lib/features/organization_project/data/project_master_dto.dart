import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// Wire shape of `/organization/projects` / `project_master`.
class ProjectMasterDto extends Equatable {
  const ProjectMasterDto({
    required this.id,
    required this.projectId,
    required this.projectName,
    this.projectCode,
    this.parentProjectMasterId,
    this.projectOwnerContactId,
    this.associatedLedgerId,
    this.godownId,
    this.coordinatorEmployeeId,
    this.projectDescription,
    this.projectStatus,
    this.startDate,
    this.endDate,
    this.estimatedValue,
    this.location,
    this.detail,
  });

  factory ProjectMasterDto.fromJson(Map<String, dynamic> json) =>
      ProjectMasterDto(
        id: json['id'] as int,
        projectId: json['PROJECT_ID'] as String? ?? '',
        projectName: json['Project_Name'] as String? ?? '',
        projectCode: json['project_code'] as String?,
        parentProjectMasterId: json['parent_project_master_id'] as int?,
        projectOwnerContactId: json['project_owner_contact_id'] as int?,
        associatedLedgerId: json['associated_ledger_id'] as int?,
        godownId: json['godown_id'] as int?,
        coordinatorEmployeeId: json['coordinator_employee_id'] as int?,
        projectDescription: json['Project_Description'] as String?,
        projectStatus: json['Project_Status'] as String?,
        startDate: _dateOnly(json['Start_Date']),
        endDate: _dateOnly(json['End_Date']),
        estimatedValue: json['Estimated_Value'] == null
            ? null
            : Decimal.parse(json['Estimated_Value'].toString()),
        location: json['Location'] as String?,
        detail: json['Detail'] as String?,
      );

  final int id;
  final String projectId;
  final String projectName;
  final String? projectCode;
  final int? parentProjectMasterId;
  final int? projectOwnerContactId;
  final int? associatedLedgerId;
  final int? godownId;
  final int? coordinatorEmployeeId;
  final String? projectDescription;
  final String? projectStatus;
  final String? startDate;
  final String? endDate;
  final Decimal? estimatedValue;
  final String? location;
  final String? detail;

  Map<String, dynamic> toJson() => {
    'PROJECT_ID': projectId,
    'Project_Name': projectName,
    if (projectCode != null && projectCode!.isNotEmpty)
      'project_code': projectCode,
    'parent_project_master_id': parentProjectMasterId,
    'project_owner_contact_id': projectOwnerContactId,
    'associated_ledger_id': associatedLedgerId,
    'godown_id': godownId,
    'coordinator_employee_id': coordinatorEmployeeId,
    if (projectDescription != null && projectDescription!.isNotEmpty)
      'Project_Description': projectDescription,
    if (projectStatus != null && projectStatus!.isNotEmpty)
      'Project_Status': projectStatus,
    if (startDate != null && startDate!.isNotEmpty) 'Start_Date': startDate,
    if (endDate != null && endDate!.isNotEmpty) 'End_Date': endDate,
    if (estimatedValue != null) 'Estimated_Value': estimatedValue!.toDouble(),
    if (location != null && location!.isNotEmpty) 'Location': location,
    if (detail != null && detail!.isNotEmpty) 'Detail': detail,
  };

  static String? _dateOnly(Object? raw) {
    if (raw == null) return null;
    final s = raw.toString();
    if (s.length >= 10) return s.substring(0, 10);
    return s.isEmpty ? null : s;
  }

  @override
  List<Object?> get props => [
    id,
    projectId,
    projectName,
    projectCode,
    parentProjectMasterId,
    projectOwnerContactId,
    associatedLedgerId,
    godownId,
    coordinatorEmployeeId,
    projectDescription,
    projectStatus,
    startDate,
    endDate,
    estimatedValue,
    location,
    detail,
  ];
}
