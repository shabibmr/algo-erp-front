import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/accounts_ledger/data/ledger_dto.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger_extensions.dart';
import 'package:decimal/decimal.dart';

class LedgerMapper implements Mapper<LedgerDto, Ledger> {
  const LedgerMapper();

  @override
  Ledger toEntity(LedgerDto dto) {
    final balance = Decimal.tryParse(dto.openingBalance) ?? Decimal.zero;
    return Ledger(
      id: dto.id,
      name: dto.ledgerName,
      code: dto.ledgerCode,
      ledgerType: dto.ledgerType,
      accountGroupId: dto.accountGroupId,
      contactId: dto.contactId,
      currencyCode: dto.currencyCode,
      isSystemDefined: dto.isSystemDefined,
      isActive: dto.isActive,
      openingBalance: balance,
      openingBalanceDate: dto.openingBalanceDate,
      bank: _bankToEntity(dto.bankDetails),
      credit: _creditToEntity(dto.creditSettings),
      tax: _taxToEntity(dto.taxSettings),
    );
  }

  @override
  LedgerDto toDto(Ledger entity) => LedgerDto(
        id: entity.id,
        ledgerName: entity.name,
        ledgerCode: entity.code,
        ledgerType: entity.ledgerType,
        accountGroupId: entity.accountGroupId,
        contactId: entity.contactId,
        currencyCode: entity.currencyCode,
        isSystemDefined: entity.isSystemDefined,
        isActive: entity.isActive,
        openingBalance: entity.openingBalance.toString(),
        openingBalanceDate: entity.openingBalanceDate,
        bankDetails:
            entity.bank.shouldWrite ? _bankToDto(entity.bank) : null,
        creditSettings:
            entity.credit.shouldWrite ? _creditToDto(entity.credit) : null,
        taxSettings: entity.tax.shouldWrite ? _taxToDto(entity.tax) : null,
      );

  static LedgerBankDetails _bankToEntity(LedgerBankDetailsDto? dto) {
    if (dto == null) return const LedgerBankDetails();
    return LedgerBankDetails(
      accountNumber: dto.bankAccountNumber,
      iban: dto.iban,
      swiftCode: dto.swiftCode,
      branchName: dto.bankBranchName,
    );
  }

  static LedgerBankDetailsDto _bankToDto(LedgerBankDetails e) =>
      LedgerBankDetailsDto(
        bankAccountNumber: e.accountNumber,
        iban: e.iban,
        swiftCode: e.swiftCode,
        bankBranchName: e.branchName,
      );

  static LedgerCreditSettings _creditToEntity(LedgerCreditSettingsDto? dto) {
    if (dto == null) return const LedgerCreditSettings();
    return LedgerCreditSettings(
      creditLimit: dto.creditLimit == null
          ? null
          : Decimal.tryParse(dto.creditLimit!),
      creditPeriodDays: dto.creditPeriodDays,
      paymentTerms: dto.paymentTerms,
      cautionDeposit: dto.cautionDeposit == null
          ? null
          : Decimal.tryParse(dto.cautionDeposit!),
    );
  }

  static LedgerCreditSettingsDto _creditToDto(LedgerCreditSettings e) =>
      LedgerCreditSettingsDto(
        creditLimit: e.creditLimit?.toString(),
        creditPeriodDays: e.creditPeriodDays,
        paymentTerms: e.paymentTerms,
        cautionDeposit: e.cautionDeposit?.toString(),
      );

  static LedgerTaxSettings _taxToEntity(LedgerTaxSettingsDto? dto) {
    if (dto == null) return const LedgerTaxSettings();
    return LedgerTaxSettings(
      trn: dto.trn,
      taxCategoryId: dto.taxCategoryId,
      typeOfSupply: dto.typeOfSupply,
    );
  }

  static LedgerTaxSettingsDto _taxToDto(LedgerTaxSettings e) =>
      LedgerTaxSettingsDto(
        trn: e.trn,
        taxCategoryId: e.taxCategoryId,
        typeOfSupply: e.typeOfSupply,
      );
}
