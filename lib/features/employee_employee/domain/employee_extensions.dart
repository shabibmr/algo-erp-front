import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

const _unset = Object();

/// 1:1 `employeebankdetails` — nested as `bankDetails` on employee create/update.
class EmployeeBankDetails extends Equatable {
  const EmployeeBankDetails({
    this.bankName,
    this.bankBranch,
    this.bankCode,
    this.accountNumber,
    this.iban,
    this.swiftCode,
    this.accountType,
  });

  final String? bankName;
  final String? bankBranch;
  final String? bankCode;
  final String? accountNumber;
  final String? iban;
  final String? swiftCode;
  final String? accountType;

  /// Only write when the user entered something meaningful.
  bool get shouldWrite =>
      (bankName != null && bankName!.trim().isNotEmpty) ||
      (accountNumber != null && accountNumber!.trim().isNotEmpty) ||
      (iban != null && iban!.trim().isNotEmpty);

  EmployeeBankDetails copyWith({
    Object? bankName = _unset,
    Object? bankBranch = _unset,
    Object? bankCode = _unset,
    Object? accountNumber = _unset,
    Object? iban = _unset,
    Object? swiftCode = _unset,
    Object? accountType = _unset,
  }) => EmployeeBankDetails(
    bankName: identical(bankName, _unset) ? this.bankName : bankName as String?,
    bankBranch: identical(bankBranch, _unset)
        ? this.bankBranch
        : bankBranch as String?,
    bankCode: identical(bankCode, _unset) ? this.bankCode : bankCode as String?,
    accountNumber: identical(accountNumber, _unset)
        ? this.accountNumber
        : accountNumber as String?,
    iban: identical(iban, _unset) ? this.iban : iban as String?,
    swiftCode: identical(swiftCode, _unset)
        ? this.swiftCode
        : swiftCode as String?,
    accountType: identical(accountType, _unset)
        ? this.accountType
        : accountType as String?,
  );

  @override
  List<Object?> get props => [
    bankName,
    bankBranch,
    bankCode,
    accountNumber,
    iban,
    swiftCode,
    accountType,
  ];
}

/// 1:1-ish `employee_salary_details` — nested as `salaryDetails`.
///
/// Money fields are [Decimal] in domain; wire numbers may be Float or string.
class EmployeeSalaryDetails extends Equatable {
  const EmployeeSalaryDetails({
    this.salaryLedgerId,
    this.advSalaryLedgerId,
    this.basicSalary,
    this.da,
    this.hra,
    this.conveyance,
    this.overtimeHourlyRate,
    this.overTimePay,
    this.monthlyLeave,
    this.weeklyLeave,
    this.annualLeave,
    this.workingHours,
    this.effectiveFrom,
  });

  final int? salaryLedgerId;
  final int? advSalaryLedgerId;
  final Decimal? basicSalary;
  final Decimal? da;
  final Decimal? hra;
  final Decimal? conveyance;
  final Decimal? overtimeHourlyRate;
  final Decimal? overTimePay;
  final int? monthlyLeave;
  final int? weeklyLeave;
  final int? annualLeave;
  final int? workingHours;
  final DateTime? effectiveFrom;

  bool get shouldWrite =>
      salaryLedgerId != null ||
      advSalaryLedgerId != null ||
      basicSalary != null ||
      da != null ||
      hra != null ||
      conveyance != null ||
      overtimeHourlyRate != null ||
      overTimePay != null ||
      monthlyLeave != null ||
      weeklyLeave != null ||
      annualLeave != null ||
      workingHours != null;

  EmployeeSalaryDetails copyWith({
    Object? salaryLedgerId = _unset,
    Object? advSalaryLedgerId = _unset,
    Object? basicSalary = _unset,
    Object? da = _unset,
    Object? hra = _unset,
    Object? conveyance = _unset,
    Object? overtimeHourlyRate = _unset,
    Object? overTimePay = _unset,
    Object? monthlyLeave = _unset,
    Object? weeklyLeave = _unset,
    Object? annualLeave = _unset,
    Object? workingHours = _unset,
    Object? effectiveFrom = _unset,
  }) => EmployeeSalaryDetails(
    salaryLedgerId: identical(salaryLedgerId, _unset)
        ? this.salaryLedgerId
        : salaryLedgerId as int?,
    advSalaryLedgerId: identical(advSalaryLedgerId, _unset)
        ? this.advSalaryLedgerId
        : advSalaryLedgerId as int?,
    basicSalary: identical(basicSalary, _unset)
        ? this.basicSalary
        : basicSalary as Decimal?,
    da: identical(da, _unset) ? this.da : da as Decimal?,
    hra: identical(hra, _unset) ? this.hra : hra as Decimal?,
    conveyance: identical(conveyance, _unset)
        ? this.conveyance
        : conveyance as Decimal?,
    overtimeHourlyRate: identical(overtimeHourlyRate, _unset)
        ? this.overtimeHourlyRate
        : overtimeHourlyRate as Decimal?,
    overTimePay: identical(overTimePay, _unset)
        ? this.overTimePay
        : overTimePay as Decimal?,
    monthlyLeave: identical(monthlyLeave, _unset)
        ? this.monthlyLeave
        : monthlyLeave as int?,
    weeklyLeave: identical(weeklyLeave, _unset)
        ? this.weeklyLeave
        : weeklyLeave as int?,
    annualLeave: identical(annualLeave, _unset)
        ? this.annualLeave
        : annualLeave as int?,
    workingHours: identical(workingHours, _unset)
        ? this.workingHours
        : workingHours as int?,
    effectiveFrom: identical(effectiveFrom, _unset)
        ? this.effectiveFrom
        : effectiveFrom as DateTime?,
  );

  @override
  List<Object?> get props => [
    salaryLedgerId,
    advSalaryLedgerId,
    basicSalary,
    da,
    hra,
    conveyance,
    overtimeHourlyRate,
    overTimePay,
    monthlyLeave,
    weeklyLeave,
    annualLeave,
    workingHours,
    effectiveFrom,
  ];
}
