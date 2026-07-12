import 'package:equatable/equatable.dart';

/// Wire shape of `/accounts/ledgers`, matching `ledger_master` +
/// `ledgerMasterSchema` (core + optional nested extensions).
class LedgerDto extends Equatable {
  const LedgerDto({
    required this.id,
    required this.ledgerName,
    required this.openingBalance,
    this.ledgerCode,
    this.ledgerType = 'Other',
    this.accountGroupId,
    this.contactId,
    this.currencyCode = 'AED',
    this.isSystemDefined = false,
    this.isActive = true,
    this.openingBalanceDate,
    this.bankDetails,
    this.creditSettings,
    this.taxSettings,
  });

  factory LedgerDto.fromJson(Map<String, dynamic> json) {
    final openingRaw = json['Opening_Balance'];
    final opening = openingRaw == null ? '0' : openingRaw.toString();
    final dateRaw = json['Opening_Balance_Date'];
    DateTime? openingDate;
    if (dateRaw is String && dateRaw.isNotEmpty) {
      openingDate = DateTime.tryParse(dateRaw);
    } else if (dateRaw is DateTime) {
      openingDate = dateRaw;
    }

    // GET include uses Prisma relation names; nested write keys differ.
    final bankRaw = json['ledger_bank_details'] ?? json['bankDetails'];
    final creditRaw = json['ledger_credit_settings'] ?? json['creditSettings'];
    final taxRaw = json['ledger_tax_settings'] ?? json['taxSettings'];

    return LedgerDto(
      id: json['id'] as int,
      ledgerName: json['Ledger_Name'] as String,
      ledgerCode: json['ledger_code'] as String?,
      ledgerType: json['Ledger_Type'] as String? ?? 'Other',
      accountGroupId: json['account_group_id'] as int?,
      contactId: json['contact_id'] as int?,
      currencyCode: json['currency_code'] as String? ?? 'AED',
      isSystemDefined: json['is_system_defined'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      openingBalance: opening,
      openingBalanceDate: openingDate,
      bankDetails: bankRaw is Map<String, dynamic>
          ? LedgerBankDetailsDto.fromJson(bankRaw)
          : null,
      creditSettings: creditRaw is Map<String, dynamic>
          ? LedgerCreditSettingsDto.fromJson(creditRaw)
          : null,
      taxSettings: taxRaw is Map<String, dynamic>
          ? LedgerTaxSettingsDto.fromJson(taxRaw)
          : null,
    );
  }

  final int id;
  final String ledgerName;
  final String? ledgerCode;
  final String ledgerType;
  final int? accountGroupId;
  final int? contactId;
  final String currencyCode;
  final bool isSystemDefined;
  final bool isActive;
  final String openingBalance;
  final DateTime? openingBalanceDate;
  final LedgerBankDetailsDto? bankDetails;
  final LedgerCreditSettingsDto? creditSettings;
  final LedgerTaxSettingsDto? taxSettings;

  /// Soft-delete flag `is_active` is owned by `DELETE`. Extensions nest under
  /// schema keys `bankDetails` / `creditSettings` / `taxSettings`.
  Map<String, dynamic> toJson() {
    String? dateOnly;
    final d = openingBalanceDate;
    if (d != null) {
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      dateOnly = '$y-$m-$day';
    }

    return {
      if (ledgerCode != null && ledgerCode!.isNotEmpty)
        'ledger_code': ledgerCode,
      'Ledger_Name': ledgerName,
      'Ledger_Type': ledgerType,
      'account_group_id': accountGroupId,
      'contact_id': contactId,
      'currency_code': currencyCode,
      'is_system_defined': isSystemDefined,
      'Opening_Balance': openingBalance,
      'Opening_Balance_Date': dateOnly,
      if (bankDetails != null) 'bankDetails': bankDetails!.toJson(),
      if (creditSettings != null) 'creditSettings': creditSettings!.toJson(),
      if (taxSettings != null) 'taxSettings': taxSettings!.toJson(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    ledgerName,
    ledgerCode,
    ledgerType,
    accountGroupId,
    contactId,
    currencyCode,
    isSystemDefined,
    isActive,
    openingBalance,
    openingBalanceDate,
    bankDetails,
    creditSettings,
    taxSettings,
  ];
}

class LedgerBankDetailsDto extends Equatable {
  const LedgerBankDetailsDto({
    required this.bankAccountNumber,
    this.iban,
    this.swiftCode,
    this.bankBranchName,
  });

  factory LedgerBankDetailsDto.fromJson(Map<String, dynamic> json) =>
      LedgerBankDetailsDto(
        bankAccountNumber: json['bank_account_number'] as String? ?? '',
        iban: json['iban'] as String?,
        swiftCode: json['swift_code'] as String?,
        bankBranchName: json['bank_branch_name'] as String?,
      );

  final String bankAccountNumber;
  final String? iban;
  final String? swiftCode;
  final String? bankBranchName;

  Map<String, dynamic> toJson() => {
    'bank_account_number': bankAccountNumber,
    'iban': iban,
    'swift_code': swiftCode,
    'bank_branch_name': bankBranchName,
  };

  @override
  List<Object?> get props => [
    bankAccountNumber,
    iban,
    swiftCode,
    bankBranchName,
  ];
}

class LedgerCreditSettingsDto extends Equatable {
  const LedgerCreditSettingsDto({
    this.creditLimit,
    this.creditPeriodDays = 0,
    this.paymentTerms,
    this.cautionDeposit,
  });

  factory LedgerCreditSettingsDto.fromJson(Map<String, dynamic> json) {
    String? numStr(dynamic v) => v?.toString();
    return LedgerCreditSettingsDto(
      creditLimit: numStr(json['credit_limit']),
      creditPeriodDays: json['credit_period_days'] as int? ?? 0,
      paymentTerms: json['payment_terms'] as String?,
      cautionDeposit: numStr(json['caution_deposit']),
    );
  }

  final String? creditLimit;
  final int creditPeriodDays;
  final String? paymentTerms;
  final String? cautionDeposit;

  Map<String, dynamic> toJson() => {
    'credit_limit': creditLimit == null ? null : double.tryParse(creditLimit!),
    'credit_period_days': creditPeriodDays,
    'payment_terms': paymentTerms,
    'caution_deposit': cautionDeposit == null
        ? null
        : double.tryParse(cautionDeposit!),
  };

  @override
  List<Object?> get props => [
    creditLimit,
    creditPeriodDays,
    paymentTerms,
    cautionDeposit,
  ];
}

class LedgerTaxSettingsDto extends Equatable {
  const LedgerTaxSettingsDto({this.trn, this.taxCategoryId, this.typeOfSupply});

  factory LedgerTaxSettingsDto.fromJson(Map<String, dynamic> json) =>
      LedgerTaxSettingsDto(
        trn: json['trn'] as String?,
        taxCategoryId: json['tax_category_id'] as int?,
        typeOfSupply: json['type_of_supply'] as String?,
      );

  final String? trn;
  final int? taxCategoryId;
  final String? typeOfSupply;

  Map<String, dynamic> toJson() => {
    'trn': trn,
    'tax_category_id': taxCategoryId,
    'type_of_supply': typeOfSupply,
  };

  @override
  List<Object?> get props => [trn, taxCategoryId, typeOfSupply];
}
