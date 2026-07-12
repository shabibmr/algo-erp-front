import 'package:equatable/equatable.dart';

class UserCredentialsDto extends Equatable {
  const UserCredentialsDto({
    required this.id,
    required this.username,
    required this.contactId,
    required this.roleId,
    this.password,
    this.branchId,
    this.employeeId,
    this.isActive = true,
  });

  factory UserCredentialsDto.fromJson(Map<String, dynamic> json) =>
      UserCredentialsDto(
        id: json['id'] as int,
        username: json['username'] as String? ?? '',
        contactId: json['contact_id'] as int? ?? 0,
        roleId: json['role_id'] as int? ?? 0,
        branchId: json['branch_id'] as int?,
        employeeId: json['employee_id'] as int?,
        isActive: json['is_active'] as bool? ?? true,
      );

  final int id;
  final String username;
  final int contactId;
  final int roleId;
  final String? password;
  final int? branchId;
  final int? employeeId;
  final bool isActive;

  /// Create body (`userCredentialsSchema`).
  Map<String, dynamic> toCreateJson() => {
    'contact_id': contactId,
    'username': username,
    'password': password ?? '',
    'role_id': roleId,
    if (branchId != null) 'branch_id': branchId,
    if (employeeId != null) 'employee_id': employeeId,
  };

  /// Update body (`userUpdateCredentialsSchema`) — no username/contact.
  Map<String, dynamic> toUpdateJson() => {
    if (password != null && password!.isNotEmpty) 'password': password,
    'role_id': roleId,
    if (branchId != null) 'branch_id': branchId,
    if (employeeId != null) 'employee_id': employeeId,
    'is_active': isActive,
  };

  @override
  List<Object?> get props => [
    id,
    username,
    contactId,
    roleId,
    branchId,
    employeeId,
    isActive,
  ];
}
