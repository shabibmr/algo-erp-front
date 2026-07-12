import 'package:equatable/equatable.dart';

/// Wire shape of `/organization/voucher-series`.
class VoucherSeriesDto extends Equatable {
  const VoucherSeriesDto({
    required this.id,
    required this.voucherType,
    required this.prefix,
    required this.displayName,
    required this.companyId,
    this.branchId,
    this.financialYearId,
    this.numberLength = 5,
    this.prefixSeparator = '/',
    this.startingNumber = 1,
    this.isDefault = false,
    this.requireApproval = false,
    this.isActive = true,
  });

  factory VoucherSeriesDto.fromJson(Map<String, dynamic> json) =>
      VoucherSeriesDto(
        id: json['id'] as int,
        voucherType: json['voucher_type'] as String? ?? '',
        prefix: json['prefix'] as String? ?? '',
        displayName: json['display_name'] as String? ?? '',
        companyId: json['company_id'] as int? ?? 0,
        branchId: json['branch_id'] as int?,
        financialYearId: json['financial_year_id'] as int?,
        numberLength: json['number_length'] as int? ?? 5,
        prefixSeparator: json['prefix_separator'] as String? ?? '/',
        startingNumber: json['starting_number'] as int? ?? 1,
        isDefault: json['is_default'] as bool? ?? false,
        requireApproval: json['require_approval'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
      );

  final int id;
  final String voucherType;
  final String prefix;
  final String displayName;
  final int companyId;
  final int? branchId;
  final int? financialYearId;
  final int numberLength;
  final String prefixSeparator;
  final int startingNumber;
  final bool isDefault;
  final bool requireApproval;
  final bool isActive;

  Map<String, dynamic> toJson() => {
    'voucher_type': voucherType,
    'prefix': prefix,
    'display_name': displayName,
    'company_id': companyId,
    'branch_id': branchId,
    'financial_year_id': financialYearId,
    'number_length': numberLength,
    'prefix_separator': prefixSeparator,
    'starting_number': startingNumber,
    'is_default': isDefault,
    'require_approval': requireApproval,
  };

  @override
  List<Object?> get props => [
    id,
    voucherType,
    prefix,
    displayName,
    companyId,
    branchId,
    financialYearId,
    numberLength,
    prefixSeparator,
    startingNumber,
    isDefault,
    requireApproval,
    isActive,
  ];
}
