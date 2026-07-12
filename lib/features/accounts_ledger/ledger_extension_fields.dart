import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/inventory_tax_category/domain/tax_category.dart';
import 'package:algo_erp_front/features/inventory_tax_category/tax_category_di.dart';
import 'package:decimal/decimal.dart';

final _taxCategoryRepository =
    createTaxCategoryRepository(getIt<DioClient>());

/// Bank tab fields — nested wire keys match Zod `bankDetails.*`.
final ledgerBankFormFields = <FormFieldSpec<Ledger>>[
  FormFieldSpec<Ledger>(
    key: 'bank.accountNumber',
    wireKey: 'bankDetails.bank_account_number',
    label: 'Account number',
    type: FieldType.text,
    helperText: 'Required to save bank details',
    getValue: (l) => l.bank.accountNumber,
    setValue: (l, v) => l.copyWith(
      bank: l.bank.copyWith(accountNumber: v as String? ?? ''),
    ),
  ),
  FormFieldSpec<Ledger>(
    key: 'bank.iban',
    wireKey: 'bankDetails.iban',
    label: 'IBAN',
    type: FieldType.text,
    getValue: (l) => l.bank.iban,
    setValue: (l, v) => l.copyWith(
      bank: l.bank.copyWith(iban: v as String?),
    ),
  ),
  FormFieldSpec<Ledger>(
    key: 'bank.swiftCode',
    wireKey: 'bankDetails.swift_code',
    label: 'SWIFT code',
    type: FieldType.text,
    getValue: (l) => l.bank.swiftCode,
    setValue: (l, v) => l.copyWith(
      bank: l.bank.copyWith(swiftCode: v as String?),
    ),
  ),
  FormFieldSpec<Ledger>(
    key: 'bank.branchName',
    wireKey: 'bankDetails.bank_branch_name',
    label: 'Branch name',
    type: FieldType.text,
    getValue: (l) => l.bank.branchName,
    setValue: (l, v) => l.copyWith(
      bank: l.bank.copyWith(branchName: v as String?),
    ),
  ),
];

/// Credit tab fields.
final ledgerCreditFormFields = <FormFieldSpec<Ledger>>[
  FormFieldSpec<Ledger>(
    key: 'credit.creditLimit',
    wireKey: 'creditSettings.credit_limit',
    label: 'Credit limit',
    type: FieldType.decimal,
    getValue: (l) => l.credit.creditLimit,
    setValue: (l, v) => l.copyWith(
      credit: l.credit.copyWith(creditLimit: v as Decimal?),
    ),
  ),
  FormFieldSpec<Ledger>(
    key: 'credit.creditPeriodDays',
    wireKey: 'creditSettings.credit_period_days',
    label: 'Credit period (days)',
    type: FieldType.int,
    getValue: (l) => l.credit.creditPeriodDays,
    setValue: (l, v) => l.copyWith(
      credit: l.credit.copyWith(creditPeriodDays: v as int? ?? 0),
    ),
  ),
  FormFieldSpec<Ledger>(
    key: 'credit.paymentTerms',
    wireKey: 'creditSettings.payment_terms',
    label: 'Payment terms',
    type: FieldType.text,
    getValue: (l) => l.credit.paymentTerms,
    setValue: (l, v) => l.copyWith(
      credit: l.credit.copyWith(paymentTerms: v as String?),
    ),
  ),
  FormFieldSpec<Ledger>(
    key: 'credit.cautionDeposit',
    wireKey: 'creditSettings.caution_deposit',
    label: 'Caution deposit',
    type: FieldType.decimal,
    getValue: (l) => l.credit.cautionDeposit,
    setValue: (l, v) => l.copyWith(
      credit: l.credit.copyWith(cautionDeposit: v as Decimal?),
    ),
  ),
];

/// Tax tab fields.
final ledgerTaxFormFields = <FormFieldSpec<Ledger>>[
  FormFieldSpec<Ledger>(
    key: 'tax.trn',
    wireKey: 'taxSettings.trn',
    label: 'TRN',
    type: FieldType.text,
    getValue: (l) => l.tax.trn,
    setValue: (l, v) => l.copyWith(
      tax: l.tax.copyWith(trn: v as String?),
    ),
  ),
  FormFieldSpec<Ledger>(
    key: 'tax.taxCategoryId',
    wireKey: 'taxSettings.tax_category_id',
    label: 'Tax category',
    type: FieldType.fk,
    getValue: (l) => l.tax.taxCategoryId,
    setValue: (l, v) => l.copyWith(
      tax: l.tax.copyWith(
        taxCategoryId: v == null ? null : (v as TaxCategory).id,
      ),
    ),
    fkSearch: (query) async {
      final result =
          await _taxCategoryRepository.list(PageQuery(search: query));
      return result.fold((_) => const [], (page) => page.items);
    },
    fkDisplayOf: (item) {
      final t = item as TaxCategory;
      return '${t.name} (${t.rate}%)';
    },
    fkResolveById: (id) async {
      final result = await _taxCategoryRepository.getById(id as int);
      return result.fold((_) => null, (t) => t);
    },
  ),
  FormFieldSpec<Ledger>(
    key: 'tax.typeOfSupply',
    wireKey: 'taxSettings.type_of_supply',
    label: 'Type of supply',
    type: FieldType.text,
    getValue: (l) => l.tax.typeOfSupply,
    setValue: (l, v) => l.copyWith(
      tax: l.tax.copyWith(typeOfSupply: v as String?),
    ),
  ),
];

/// All form fields (core + extensions) for error seeding / FK resolve.
List<FormFieldSpec<Ledger>> allLedgerFormFields(
  List<FormFieldSpec<Ledger>> core,
) =>
    [
      ...core,
      ...ledgerBankFormFields,
      ...ledgerCreditFormFields,
      ...ledgerTaxFormFields,
    ];
