import 'package:equatable/equatable.dart';

class LeavePolicyDto extends Equatable {
  const LeavePolicyDto({
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

  factory LeavePolicyDto.fromJson(Map<String, dynamic> json) => LeavePolicyDto(
    id: json['id'] as int,
    leaveType: json['leave_type'] as String? ?? '',
    displayName: json['display_name'] as String? ?? '',
    maxDaysPerYear: json['max_days_per_year'] as int? ?? 0,
    maxDaysPerRequest: json['max_days_per_request'] as int?,
    carryForwardLimit: json['carry_forward_limit'] as int? ?? 0,
    requiresApproval: json['requires_approval'] as bool? ?? true,
    isPaid: json['is_paid'] as bool? ?? true,
    applicableGender: json['applicable_gender'] as String?,
    isActive: json['is_active'] as bool? ?? true,
  );

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

  Map<String, dynamic> toJson() => {
    'leave_type': leaveType,
    'display_name': displayName,
    'max_days_per_year': maxDaysPerYear,
    'max_days_per_request': maxDaysPerRequest,
    'carry_forward_limit': carryForwardLimit,
    'requires_approval': requiresApproval,
    'is_paid': isPaid,
    'applicable_gender': applicableGender,
    'is_active': isActive,
  };

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
