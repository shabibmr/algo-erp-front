import 'package:algo_erp_front/features/accounts_ledger/domain/ledger_extensions.dart';
import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

const _unset = Object();

/// Ledger master — soft-deleted via `is_active`. Optional 1:1 bank / credit /
/// tax extensions nest into create/update payloads (`bankDetails`, etc.).
class Ledger extends Equatable {
  const Ledger({
    required this.id,
    required this.name,
    required this.openingBalance,
    this.code,
    this.ledgerType = 'Other',
    this.accountGroupId,
    this.contactId,
    this.currencyCode = 'AED',
    this.isSystemDefined = false,
    this.isActive = true,
    this.openingBalanceDate,
    this.bank = const LedgerBankDetails(),
    this.credit = const LedgerCreditSettings(),
    this.tax = const LedgerTaxSettings(),
  });

  /// Values accepted by `ledgerMasterSchema`'s `Ledger_Type` enum.
  static const ledgerTypes = [
    'SundryDebtor',
    'SundryCreditor',
    'Bank',
    'Cash',
    'Expense',
    'Income',
    'Tax',
    'FixedAsset',
    'Capital',
    'DutyTax',
    'Stock',
    'Other',
  ];

  final int id;
  final String name;
  final String? code;
  final String ledgerType;
  final int? accountGroupId;
  final int? contactId;
  final String currencyCode;
  final bool isSystemDefined;
  final bool isActive;

  /// Opening balance as [Decimal] — never `double` (wire is a string).
  final Decimal openingBalance;
  final DateTime? openingBalanceDate;

  final LedgerBankDetails bank;
  final LedgerCreditSettings credit;
  final LedgerTaxSettings tax;

  Ledger copyWith({
    int? id,
    String? name,
    Object? code = _unset,
    String? ledgerType,
    Object? accountGroupId = _unset,
    Object? contactId = _unset,
    String? currencyCode,
    bool? isSystemDefined,
    bool? isActive,
    Decimal? openingBalance,
    Object? openingBalanceDate = _unset,
    LedgerBankDetails? bank,
    LedgerCreditSettings? credit,
    LedgerTaxSettings? tax,
  }) => Ledger(
    id: id ?? this.id,
    name: name ?? this.name,
    code: identical(code, _unset) ? this.code : code as String?,
    ledgerType: ledgerType ?? this.ledgerType,
    accountGroupId: identical(accountGroupId, _unset)
        ? this.accountGroupId
        : accountGroupId as int?,
    contactId: identical(contactId, _unset)
        ? this.contactId
        : contactId as int?,
    currencyCode: currencyCode ?? this.currencyCode,
    isSystemDefined: isSystemDefined ?? this.isSystemDefined,
    isActive: isActive ?? this.isActive,
    openingBalance: openingBalance ?? this.openingBalance,
    openingBalanceDate: identical(openingBalanceDate, _unset)
        ? this.openingBalanceDate
        : openingBalanceDate as DateTime?,
    bank: bank ?? this.bank,
    credit: credit ?? this.credit,
    tax: tax ?? this.tax,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    ledgerType,
    accountGroupId,
    contactId,
    currencyCode,
    isSystemDefined,
    isActive,
    openingBalance,
    openingBalanceDate,
    bank,
    credit,
    tax,
  ];
}
