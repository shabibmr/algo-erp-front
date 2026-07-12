import 'package:equatable/equatable.dart';

const _unset = Object();

/// Voucher numbering series — soft-deleted via `is_active`.
/// Holds `require_approval` (optional approval workflow per type+prefix).
class VoucherSeries extends Equatable {
  const VoucherSeries({
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

  /// Common voucher_type values (free string on backend).
  static const voucherTypes = [
    'SalesInvoice',
    'PurchaseInvoice',
    'Payment',
    'Receipt',
    'Journal',
    'Contra',
    'CreditNote',
    'DebitNote',
    'Quotation',
    'SalesOrder',
    'PurchaseOrder',
    'DeliveryNote',
    'ReceiptNote',
    'GodownTransfer',
  ];

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

  VoucherSeries copyWith({
    int? id,
    String? voucherType,
    String? prefix,
    String? displayName,
    int? companyId,
    Object? branchId = _unset,
    Object? financialYearId = _unset,
    int? numberLength,
    String? prefixSeparator,
    int? startingNumber,
    bool? isDefault,
    bool? requireApproval,
    bool? isActive,
  }) => VoucherSeries(
    id: id ?? this.id,
    voucherType: voucherType ?? this.voucherType,
    prefix: prefix ?? this.prefix,
    displayName: displayName ?? this.displayName,
    companyId: companyId ?? this.companyId,
    branchId: identical(branchId, _unset) ? this.branchId : branchId as int?,
    financialYearId: identical(financialYearId, _unset)
        ? this.financialYearId
        : financialYearId as int?,
    numberLength: numberLength ?? this.numberLength,
    prefixSeparator: prefixSeparator ?? this.prefixSeparator,
    startingNumber: startingNumber ?? this.startingNumber,
    isDefault: isDefault ?? this.isDefault,
    requireApproval: requireApproval ?? this.requireApproval,
    isActive: isActive ?? this.isActive,
  );

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
