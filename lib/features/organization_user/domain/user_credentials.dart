import 'package:equatable/equatable.dart';

const _unset = Object();

/// Login user (UserCredentials). [password] is write-only — never returned
/// by the API; omit empty password on update.
class UserCredentials extends Equatable {
  const UserCredentials({
    required this.id,
    required this.username,
    required this.contactId,
    required this.roleId,
    this.password,
    this.branchId,
    this.employeeId,
    this.isActive = true,
  });

  final int id;
  final String username;
  final int contactId;
  final int roleId;

  /// Create/update write-only; never loaded from GET.
  final String? password;
  final int? branchId;
  final int? employeeId;
  final bool isActive;

  UserCredentials copyWith({
    int? id,
    String? username,
    int? contactId,
    int? roleId,
    Object? password = _unset,
    Object? branchId = _unset,
    Object? employeeId = _unset,
    bool? isActive,
  }) => UserCredentials(
    id: id ?? this.id,
    username: username ?? this.username,
    contactId: contactId ?? this.contactId,
    roleId: roleId ?? this.roleId,
    password: identical(password, _unset) ? this.password : password as String?,
    branchId: identical(branchId, _unset) ? this.branchId : branchId as int?,
    employeeId: identical(employeeId, _unset)
        ? this.employeeId
        : employeeId as int?,
    isActive: isActive ?? this.isActive,
  );

  @override
  List<Object?> get props => [
    id,
    username,
    contactId,
    roleId,
    password,
    branchId,
    employeeId,
    isActive,
  ];
}
