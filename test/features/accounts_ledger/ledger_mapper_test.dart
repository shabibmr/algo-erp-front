import 'package:algo_erp_front/features/accounts_ledger/data/ledger_dto.dart';
import 'package:algo_erp_front/features/accounts_ledger/data/ledger_mapper.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger_extensions.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = LedgerMapper();

  test("LedgerDto.fromJson reads the backend's wire casing", () {
    final dto = LedgerDto.fromJson(const {
      'id': 10,
      'ledger_code': 'CUST-1',
      'Ledger_Name': 'Customer A',
      'Ledger_Type': 'SundryDebtor',
      'account_group_id': 3,
      'contact_id': 7,
      'currency_code': 'AED',
      'is_system_defined': false,
      'is_active': true,
      'Opening_Balance': '1500.50',
      'Opening_Balance_Date': '2025-04-01',
    });

    expect(dto.id, 10);
    expect(dto.ledgerCode, 'CUST-1');
    expect(dto.ledgerName, 'Customer A');
    expect(dto.ledgerType, 'SundryDebtor');
    expect(dto.accountGroupId, 3);
    expect(dto.contactId, 7);
    expect(dto.openingBalance, '1500.50');
    expect(dto.openingBalanceDate, DateTime(2025, 4, 1));
    expect(dto.bankDetails, isNull);
  });

  test('LedgerDto.fromJson parses nested Prisma relation names', () {
    final dto = LedgerDto.fromJson(const {
      'id': 1,
      'Ledger_Name': 'Customer A',
      'Opening_Balance': '0',
      'ledger_bank_details': {
        'ledger_id': 1,
        'bank_account_number': '123',
        'iban': 'AE00',
        'swift_code': 'SWFT',
        'bank_branch_name': 'Main',
      },
      'ledger_credit_settings': {
        'ledger_id': 1,
        'credit_limit': '5000.00',
        'credit_period_days': 30,
        'payment_terms': 'Net 30',
        'caution_deposit': 100,
      },
      'ledger_tax_settings': {
        'ledger_id': 1,
        'trn': '100123',
        'tax_category_id': 2,
        'type_of_supply': 'Goods',
      },
    });

    expect(dto.bankDetails?.bankAccountNumber, '123');
    expect(dto.bankDetails?.iban, 'AE00');
    expect(dto.creditSettings?.creditPeriodDays, 30);
    expect(dto.creditSettings?.creditLimit, '5000.00');
    expect(dto.taxSettings?.trn, '100123');
    expect(dto.taxSettings?.taxCategoryId, 2);

    final entity = mapper.toEntity(dto);
    expect(entity.bank.accountNumber, '123');
    expect(entity.credit.creditPeriodDays, 30);
    expect(entity.credit.creditLimit, Decimal.parse('5000.00'));
    expect(entity.tax.trn, '100123');
    expect(entity.tax.taxCategoryId, 2);
  });

  test('LedgerDto.fromJson parses numeric Opening_Balance', () {
    final dto = LedgerDto.fromJson(const {
      'id': 1,
      'Ledger_Name': 'Cash',
      'Opening_Balance': 0,
    });
    expect(dto.openingBalance, '0');
  });

  test('LedgerMapper.toEntity uses Decimal for opening balance', () {
    const dto = LedgerDto(
      id: 1,
      ledgerName: 'Cash',
      ledgerType: 'Cash',
      openingBalance: '99.01',
    );
    final entity = mapper.toEntity(dto);

    expect(entity.name, 'Cash');
    expect(entity.openingBalance, Decimal.parse('99.01'));
    expect(entity.ledgerType, 'Cash');
  });

  test('toJson nests extensions only when shouldWrite', () {
    final ledger = Ledger(
      id: 1,
      name: 'Customer A',
      code: 'C1',
      ledgerType: 'SundryDebtor',
      accountGroupId: 2,
      contactId: 9,
      currencyCode: 'AED',
      openingBalance: Decimal.parse('10.00'),
      openingBalanceDate: DateTime(2025, 4, 1),
      bank: const LedgerBankDetails(accountNumber: 'ACC-9', iban: 'AE11'),
      credit: LedgerCreditSettings(
        creditLimit: Decimal.parse('1000'),
        creditPeriodDays: 15,
      ),
      tax: const LedgerTaxSettings(trn: 'TRN1', taxCategoryId: 3),
    );
    final json = mapper.toDto(ledger).toJson();

    expect(json['Ledger_Name'], 'Customer A');
    expect(json['Opening_Balance_Date'], '2025-04-01');
    expect(json['bankDetails'], isA<Map<String, dynamic>>());
    expect(json['bankDetails']['bank_account_number'], 'ACC-9');
    expect(json['creditSettings']['credit_period_days'], 15);
    expect(json['taxSettings']['trn'], 'TRN1');
    expect(json.containsKey('is_active'), isFalse);
  });

  test('toJson omits empty bankDetails (account number required)', () {
    final ledger = Ledger(
      id: 1,
      name: 'Cash',
      ledgerType: 'Cash',
      openingBalance: Decimal.zero,
      bank: const LedgerBankDetails(iban: 'AE00'),
    );
    final json = mapper.toDto(ledger).toJson();
    expect(json.containsKey('bankDetails'), isFalse);
  });

  test('round-trip toEntity(toDto(x)) is identity when extensions write', () {
    final ledger = Ledger(
      id: 4,
      name: 'Bank',
      ledgerType: 'Bank',
      openingBalance: Decimal.parse('0'),
      currencyCode: 'AED',
      bank: const LedgerBankDetails(accountNumber: '1', branchName: 'HQ'),
      credit: const LedgerCreditSettings(creditPeriodDays: 7),
      tax: const LedgerTaxSettings(typeOfSupply: 'Services'),
    );
    expect(mapper.toEntity(mapper.toDto(ledger)), ledger);
  });
}
