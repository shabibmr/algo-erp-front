import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/employee_employee/domain/employee.dart';
import 'package:decimal/decimal.dart';

final _ledgerRepository = createLedgerRepository(getIt<DioClient>());

/// Bank tab — nested wire keys match Zod `bankDetails.*`.
final employeeBankFormFields = <FormFieldSpec<Employee>>[
  FormFieldSpec<Employee>(
    key: 'bank.bankName',
    wireKey: 'bankDetails.bank_name',
    label: 'Bank name',
    type: FieldType.text,
    getValue: (e) => e.bank.bankName,
    setValue: (e, v) =>
        e.copyWith(bank: e.bank.copyWith(bankName: v as String?)),
  ),
  FormFieldSpec<Employee>(
    key: 'bank.bankBranch',
    wireKey: 'bankDetails.bank_branch',
    label: 'Branch',
    type: FieldType.text,
    getValue: (e) => e.bank.bankBranch,
    setValue: (e, v) =>
        e.copyWith(bank: e.bank.copyWith(bankBranch: v as String?)),
  ),
  FormFieldSpec<Employee>(
    key: 'bank.bankCode',
    wireKey: 'bankDetails.bank_code',
    label: 'Bank code',
    type: FieldType.text,
    getValue: (e) => e.bank.bankCode,
    setValue: (e, v) =>
        e.copyWith(bank: e.bank.copyWith(bankCode: v as String?)),
  ),
  FormFieldSpec<Employee>(
    key: 'bank.accountNumber',
    wireKey: 'bankDetails.account_number',
    label: 'Account number',
    type: FieldType.text,
    getValue: (e) => e.bank.accountNumber,
    setValue: (e, v) =>
        e.copyWith(bank: e.bank.copyWith(accountNumber: v as String?)),
  ),
  FormFieldSpec<Employee>(
    key: 'bank.iban',
    wireKey: 'bankDetails.iban',
    label: 'IBAN',
    type: FieldType.text,
    getValue: (e) => e.bank.iban,
    setValue: (e, v) => e.copyWith(bank: e.bank.copyWith(iban: v as String?)),
  ),
  FormFieldSpec<Employee>(
    key: 'bank.swiftCode',
    wireKey: 'bankDetails.swift_code',
    label: 'SWIFT code',
    type: FieldType.text,
    getValue: (e) => e.bank.swiftCode,
    setValue: (e, v) =>
        e.copyWith(bank: e.bank.copyWith(swiftCode: v as String?)),
  ),
  FormFieldSpec<Employee>(
    key: 'bank.accountType',
    wireKey: 'bankDetails.account_type',
    label: 'Account type',
    type: FieldType.text,
    helperText: 'Savings, Current, WPS',
    getValue: (e) => e.bank.accountType,
    setValue: (e, v) =>
        e.copyWith(bank: e.bank.copyWith(accountType: v as String?)),
  ),
];

/// Salary tab — nested wire keys match Zod `salaryDetails.*`.
final employeeSalaryFormFields = <FormFieldSpec<Employee>>[
  FormFieldSpec<Employee>(
    key: 'salary.salaryLedgerId',
    wireKey: 'salaryDetails.salary_ledger_id',
    label: 'Salary ledger',
    type: FieldType.fk,
    getValue: (e) => e.salary.salaryLedgerId,
    setValue: (e, v) => e.copyWith(
      salary: e.salary.copyWith(
        salaryLedgerId: v == null ? null : (v as Ledger).id,
      ),
    ),
    fkSearch: (query) async {
      final result = await _ledgerRepository.list(PageQuery(search: query));
      return result.fold((_) => const [], (page) => page.items);
    },
    fkDisplayOf: (item) => (item as Ledger).name,
    fkResolveById: (id) async {
      final result = await _ledgerRepository.getById(id as int);
      return result.fold((_) => null, (l) => l);
    },
  ),
  FormFieldSpec<Employee>(
    key: 'salary.advSalaryLedgerId',
    wireKey: 'salaryDetails.adv_salary_ledger_id',
    label: 'Advance salary ledger',
    type: FieldType.fk,
    getValue: (e) => e.salary.advSalaryLedgerId,
    setValue: (e, v) => e.copyWith(
      salary: e.salary.copyWith(
        advSalaryLedgerId: v == null ? null : (v as Ledger).id,
      ),
    ),
    fkSearch: (query) async {
      final result = await _ledgerRepository.list(PageQuery(search: query));
      return result.fold((_) => const [], (page) => page.items);
    },
    fkDisplayOf: (item) => (item as Ledger).name,
    fkResolveById: (id) async {
      final result = await _ledgerRepository.getById(id as int);
      return result.fold((_) => null, (l) => l);
    },
  ),
  FormFieldSpec<Employee>(
    key: 'salary.basicSalary',
    wireKey: 'salaryDetails.Basic_Salary',
    label: 'Basic salary',
    type: FieldType.decimal,
    getValue: (e) => e.salary.basicSalary,
    setValue: (e, v) =>
        e.copyWith(salary: e.salary.copyWith(basicSalary: v as Decimal?)),
  ),
  FormFieldSpec<Employee>(
    key: 'salary.da',
    wireKey: 'salaryDetails.DA',
    label: 'DA',
    type: FieldType.decimal,
    getValue: (e) => e.salary.da,
    setValue: (e, v) =>
        e.copyWith(salary: e.salary.copyWith(da: v as Decimal?)),
  ),
  FormFieldSpec<Employee>(
    key: 'salary.hra',
    wireKey: 'salaryDetails.HRA',
    label: 'HRA',
    type: FieldType.decimal,
    getValue: (e) => e.salary.hra,
    setValue: (e, v) =>
        e.copyWith(salary: e.salary.copyWith(hra: v as Decimal?)),
  ),
  FormFieldSpec<Employee>(
    key: 'salary.conveyance',
    wireKey: 'salaryDetails.Conveyance',
    label: 'Conveyance',
    type: FieldType.decimal,
    getValue: (e) => e.salary.conveyance,
    setValue: (e, v) =>
        e.copyWith(salary: e.salary.copyWith(conveyance: v as Decimal?)),
  ),
  FormFieldSpec<Employee>(
    key: 'salary.overtimeHourlyRate',
    wireKey: 'salaryDetails.overtime_hourly_rate',
    label: 'Overtime hourly rate',
    type: FieldType.decimal,
    getValue: (e) => e.salary.overtimeHourlyRate,
    setValue: (e, v) => e.copyWith(
      salary: e.salary.copyWith(overtimeHourlyRate: v as Decimal?),
    ),
  ),
  FormFieldSpec<Employee>(
    key: 'salary.overTimePay',
    wireKey: 'salaryDetails.OverTime_Pay',
    label: 'OT multiplier',
    type: FieldType.decimal,
    getValue: (e) => e.salary.overTimePay,
    setValue: (e, v) =>
        e.copyWith(salary: e.salary.copyWith(overTimePay: v as Decimal?)),
  ),
  FormFieldSpec<Employee>(
    key: 'salary.monthlyLeave',
    wireKey: 'salaryDetails.Monthly_Leave',
    label: 'Monthly leave days',
    type: FieldType.int,
    getValue: (e) => e.salary.monthlyLeave,
    setValue: (e, v) =>
        e.copyWith(salary: e.salary.copyWith(monthlyLeave: v as int?)),
  ),
  FormFieldSpec<Employee>(
    key: 'salary.weeklyLeave',
    wireKey: 'salaryDetails.Weekly_Leave',
    label: 'Weekly leave days',
    type: FieldType.int,
    getValue: (e) => e.salary.weeklyLeave,
    setValue: (e, v) =>
        e.copyWith(salary: e.salary.copyWith(weeklyLeave: v as int?)),
  ),
  FormFieldSpec<Employee>(
    key: 'salary.annualLeave',
    wireKey: 'salaryDetails.Annual_Leave',
    label: 'Annual leave days',
    type: FieldType.int,
    getValue: (e) => e.salary.annualLeave,
    setValue: (e, v) =>
        e.copyWith(salary: e.salary.copyWith(annualLeave: v as int?)),
  ),
  FormFieldSpec<Employee>(
    key: 'salary.workingHours',
    wireKey: 'salaryDetails.Working_Hours',
    label: 'Working hours',
    type: FieldType.int,
    getValue: (e) => e.salary.workingHours,
    setValue: (e, v) =>
        e.copyWith(salary: e.salary.copyWith(workingHours: v as int?)),
  ),
  FormFieldSpec<Employee>(
    key: 'salary.effectiveFrom',
    wireKey: 'salaryDetails.effective_from',
    label: 'Effective from',
    type: FieldType.dateTime,
    getValue: (e) => e.salary.effectiveFrom,
    setValue: (e, v) =>
        e.copyWith(salary: e.salary.copyWith(effectiveFrom: v as DateTime?)),
  ),
];

List<FormFieldSpec<Employee>> allEmployeeFormFields(
  List<FormFieldSpec<Employee>> core,
) => [...core, ...employeeBankFormFields, ...employeeSalaryFormFields];
