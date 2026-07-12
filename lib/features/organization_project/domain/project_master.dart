import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

const _unset = Object();

/// Project master — hard-delete (no `is_active`). Optional self-FK parent.
class ProjectMaster extends Equatable {
  const ProjectMaster({
    required this.id,
    required this.projectId,
    required this.name,
    this.projectCode,
    this.parentProjectMasterId,
    this.projectOwnerContactId,
    this.associatedLedgerId,
    this.godownId,
    this.coordinatorEmployeeId,
    this.description,
    this.status,
    this.startDate,
    this.endDate,
    this.estimatedValue,
    this.location,
    this.detail,
  });

  /// Backend `Project_Status` enum values from `projectMasterSchema`.
  static const statuses = [
    'Pending',
    'Active',
    'OnHold',
    'Completed',
    'Cancelled',
  ];

  final int id;

  /// Legacy unique string column `PROJECT_ID` (required by API).
  final String projectId;
  final String name;
  final String? projectCode;
  final int? parentProjectMasterId;
  final int? projectOwnerContactId;
  final int? associatedLedgerId;
  final int? godownId;
  final int? coordinatorEmployeeId;
  final String? description;
  final String? status;

  /// `YYYY-MM-DD` strings (schema regex), not [DateTime].
  final String? startDate;
  final String? endDate;
  final Decimal? estimatedValue;
  final String? location;
  final String? detail;

  ProjectMaster copyWith({
    int? id,
    String? projectId,
    String? name,
    Object? projectCode = _unset,
    Object? parentProjectMasterId = _unset,
    Object? projectOwnerContactId = _unset,
    Object? associatedLedgerId = _unset,
    Object? godownId = _unset,
    Object? coordinatorEmployeeId = _unset,
    Object? description = _unset,
    Object? status = _unset,
    Object? startDate = _unset,
    Object? endDate = _unset,
    Object? estimatedValue = _unset,
    Object? location = _unset,
    Object? detail = _unset,
  }) => ProjectMaster(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    name: name ?? this.name,
    projectCode: identical(projectCode, _unset)
        ? this.projectCode
        : projectCode as String?,
    parentProjectMasterId: identical(parentProjectMasterId, _unset)
        ? this.parentProjectMasterId
        : parentProjectMasterId as int?,
    projectOwnerContactId: identical(projectOwnerContactId, _unset)
        ? this.projectOwnerContactId
        : projectOwnerContactId as int?,
    associatedLedgerId: identical(associatedLedgerId, _unset)
        ? this.associatedLedgerId
        : associatedLedgerId as int?,
    godownId: identical(godownId, _unset) ? this.godownId : godownId as int?,
    coordinatorEmployeeId: identical(coordinatorEmployeeId, _unset)
        ? this.coordinatorEmployeeId
        : coordinatorEmployeeId as int?,
    description: identical(description, _unset)
        ? this.description
        : description as String?,
    status: identical(status, _unset) ? this.status : status as String?,
    startDate: identical(startDate, _unset)
        ? this.startDate
        : startDate as String?,
    endDate: identical(endDate, _unset) ? this.endDate : endDate as String?,
    estimatedValue: identical(estimatedValue, _unset)
        ? this.estimatedValue
        : estimatedValue as Decimal?,
    location: identical(location, _unset) ? this.location : location as String?,
    detail: identical(detail, _unset) ? this.detail : detail as String?,
  );

  @override
  List<Object?> get props => [
    id,
    projectId,
    name,
    projectCode,
    parentProjectMasterId,
    projectOwnerContactId,
    associatedLedgerId,
    godownId,
    coordinatorEmployeeId,
    description,
    status,
    startDate,
    endDate,
    estimatedValue,
    location,
    detail,
  ];
}
