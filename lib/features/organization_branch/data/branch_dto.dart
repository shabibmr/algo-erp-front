import 'package:equatable/equatable.dart';

/// Wire shape of `/organization/branches`, matching the backend `branch` table.
class BranchDto extends Equatable {
  const BranchDto({
    required this.id,
    required this.branchCode,
    required this.branchName,
    required this.companyId,
    this.address,
    this.isActive = true,
  });

  factory BranchDto.fromJson(Map<String, dynamic> json) => BranchDto(
    id: json['id'] as int,
    branchCode: json['branch_code'] as String,
    branchName: json['branch_name'] as String,
    companyId: json['company_id'] as int,
    address: json['address'] as String?,
    isActive: json['is_active'] as bool? ?? true,
  );

  final int id;
  final String branchCode;
  final String branchName;
  final int companyId;
  final String? address;
  final bool isActive;

  /// `id`/timestamps are server-generated and never sent on write. `is_active`
  /// is omitted too: it is the soft-delete flag, owned by `DELETE`, and
  /// `branchSchema` does not accept it on create/update.
  Map<String, dynamic> toJson() => {
    'branch_code': branchCode,
    'branch_name': branchName,
    'company_id': companyId,
    'address': address,
  };

  @override
  List<Object?> get props => [
    id,
    branchCode,
    branchName,
    companyId,
    address,
    isActive,
  ];
}
