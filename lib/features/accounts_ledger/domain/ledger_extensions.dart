import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

const _unset = Object();

/// 1:1 `ledger_bank_details` — written nested as `bankDetails` on ledger
/// create/update. Only sent when [accountNumber] is non-empty (API requires it).
class LedgerBankDetails extends Equatable {
  const LedgerBankDetails({
    this.accountNumber = '',
    this.iban,
    this.swiftCode,
    this.branchName,
  });

  final String accountNumber;
  final String? iban;
  final String? swiftCode;
  final String? branchName;

  bool get shouldWrite => accountNumber.trim().isNotEmpty;

  LedgerBankDetails copyWith({
    String? accountNumber,
    Object? iban = _unset,
    Object? swiftCode = _unset,
    Object? branchName = _unset,
  }) => LedgerBankDetails(
    accountNumber: accountNumber ?? this.accountNumber,
    iban: identical(iban, _unset) ? this.iban : iban as String?,
    swiftCode: identical(swiftCode, _unset)
        ? this.swiftCode
        : swiftCode as String?,
    branchName: identical(branchName, _unset)
        ? this.branchName
        : branchName as String?,
  );

  @override
  List<Object?> get props => [accountNumber, iban, swiftCode, branchName];
}

/// 1:1 `ledger_credit_settings` — nested as `creditSettings`.
class LedgerCreditSettings extends Equatable {
  const LedgerCreditSettings({
    this.creditLimit,
    this.creditPeriodDays = 0,
    this.paymentTerms,
    this.cautionDeposit,
  });

  final Decimal? creditLimit;
  final int creditPeriodDays;
  final String? paymentTerms;
  final Decimal? cautionDeposit;

  bool get shouldWrite =>
      creditLimit != null ||
      creditPeriodDays != 0 ||
      (paymentTerms != null && paymentTerms!.isNotEmpty) ||
      cautionDeposit != null;

  LedgerCreditSettings copyWith({
    Object? creditLimit = _unset,
    int? creditPeriodDays,
    Object? paymentTerms = _unset,
    Object? cautionDeposit = _unset,
  }) => LedgerCreditSettings(
    creditLimit: identical(creditLimit, _unset)
        ? this.creditLimit
        : creditLimit as Decimal?,
    creditPeriodDays: creditPeriodDays ?? this.creditPeriodDays,
    paymentTerms: identical(paymentTerms, _unset)
        ? this.paymentTerms
        : paymentTerms as String?,
    cautionDeposit: identical(cautionDeposit, _unset)
        ? this.cautionDeposit
        : cautionDeposit as Decimal?,
  );

  @override
  List<Object?> get props => [
    creditLimit,
    creditPeriodDays,
    paymentTerms,
    cautionDeposit,
  ];
}

/// 1:1 `ledger_tax_settings` — nested as `taxSettings`.
class LedgerTaxSettings extends Equatable {
  const LedgerTaxSettings({this.trn, this.taxCategoryId, this.typeOfSupply});

  final String? trn;
  final int? taxCategoryId;
  final String? typeOfSupply;

  bool get shouldWrite =>
      (trn != null && trn!.isNotEmpty) ||
      taxCategoryId != null ||
      (typeOfSupply != null && typeOfSupply!.isNotEmpty);

  LedgerTaxSettings copyWith({
    Object? trn = _unset,
    Object? taxCategoryId = _unset,
    Object? typeOfSupply = _unset,
  }) => LedgerTaxSettings(
    trn: identical(trn, _unset) ? this.trn : trn as String?,
    taxCategoryId: identical(taxCategoryId, _unset)
        ? this.taxCategoryId
        : taxCategoryId as int?,
    typeOfSupply: identical(typeOfSupply, _unset)
        ? this.typeOfSupply
        : typeOfSupply as String?,
  );

  @override
  List<Object?> get props => [trn, taxCategoryId, typeOfSupply];
}
