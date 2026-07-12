import 'package:equatable/equatable.dart';

const _unset = Object();

/// Leave policy master. Backend exposes list + create only (no get/put/delete).
class LeavePolicy extends Equatable {
  const LeavePolicy({
    required this.id,
    required this.leaveType,
    required this.displayName,
    this.maxDaysPerYear = 0,
    this.maxDaysPerRequest,
    this.carryForwardLimit = 0,
    this.requiresApproval = true,
    this.isPaid = true,
    this.applicableGender,
    this.isActive = true,
  });

  static const leaveTypes = [
    'Annual',
    'Sick',
    'Emergency',
    'Maternity',
    'Paternity',
    'Unpaid',
    'Compensatory',
    'Other',
  ];

  final int id;
  final String leaveType;
  final String displayName;
  final int maxDaysPerYear;
  final int? maxDaysPerRequest;
  final int carryForwardLimit;
  final bool requiresApproval;
  final bool isPaid;
  final String? applicableGender;
  final bool isActive;

  LeavePolicy copyWith({
    int? id,
    String? leaveType,
    String? displayName,
    int? maxDaysPerYear,
    Object? maxDaysPerRequest = _unset,
    int? carryForwardLimit,
    bool? requiresApproval,
    bool? isPaid,
    Object? applicableGender = _unset,
    bool? isActive,
  }) => LeavePolicy(
    id: id ?? this.id,
    leaveType: leaveType ?? this.leaveType,
    displayName: displayName ?? this.displayName,
    maxDaysPerYear: maxDaysPerYear ?? this.maxDaysPerYear,
    maxDaysPerRequest: identical(maxDaysPerRequest, _unset)
        ? this.maxDaysPerRequest
        : maxDaysPerRequest as int?,
    carryForwardLimit: carryForwardLimit ?? this.carryForwardLimit,
    requiresApproval: requiresApproval ?? this.requiresApproval,
    isPaid: isPaid ?? this.isPaid,
    applicableGender: identical(applicableGender, _unset)
        ? this.applicableGender
        : applicableGender as String?,
    isActive: isActive ?? this.isActive,
  );

  @override
  List<Object?> get props => [
    id,
    leaveType,
    displayName,
    maxDaysPerYear,
    maxDaysPerRequest,
    carryForwardLimit,
    requiresApproval,
    isPaid,
    applicableGender,
    isActive,
  ];
}
