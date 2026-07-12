import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/employee_employee/data/employee_dto.dart';
import 'package:algo_erp_front/features/employee_employee/domain/employee.dart';
import 'package:algo_erp_front/features/employee_employee/domain/employee_extensions.dart';
import 'package:decimal/decimal.dart';

class EmployeeMapper implements Mapper<EmployeeDto, Employee> {
  const EmployeeMapper();

  @override
  Employee toEntity(EmployeeDto dto) => Employee(
    id: dto.id,
    name: dto.name,
    code: dto.employeeCode,
    contactId: dto.contactId,
    fathersName: dto.fathersName,
    dateOfBirth: dto.dateOfBirth,
    gender: dto.gender,
    nationality: dto.nationality,
    maritalStatus: dto.maritalStatus,
    phone: dto.phone,
    designationId: dto.designationId,
    departmentId: dto.departmentId,
    dateOfJoining: dto.dateOfJoining,
    dateOfLeaving: dto.dateOfLeaving,
    biometricId: dto.biometricId,
    highestQualification: dto.highestQualification,
    dateOfQualification: dto.dateOfQualification,
    emergencyContactName: dto.emergencyContactName,
    emergencyContactNo: dto.emergencyContactNo,
    emergencyContactRelation: dto.emergencyContactRelation,
    showEmployee: dto.showEmployee,
    isActive: dto.isActive,
    bank: _bankToEntity(dto.bankDetails),
    salary: _salaryToEntity(dto.salaryDetails),
  );

  @override
  EmployeeDto toDto(Employee entity) => EmployeeDto(
    id: entity.id,
    name: entity.name,
    employeeCode: entity.code,
    contactId: entity.contactId,
    fathersName: entity.fathersName,
    dateOfBirth: entity.dateOfBirth,
    gender: entity.gender,
    nationality: entity.nationality,
    maritalStatus: entity.maritalStatus,
    phone: entity.phone,
    designationId: entity.designationId,
    departmentId: entity.departmentId,
    dateOfJoining: entity.dateOfJoining,
    dateOfLeaving: entity.dateOfLeaving,
    biometricId: entity.biometricId,
    highestQualification: entity.highestQualification,
    dateOfQualification: entity.dateOfQualification,
    emergencyContactName: entity.emergencyContactName,
    emergencyContactNo: entity.emergencyContactNo,
    emergencyContactRelation: entity.emergencyContactRelation,
    showEmployee: entity.showEmployee,
    isActive: entity.isActive,
    bankDetails: entity.bank.shouldWrite ? _bankToDto(entity.bank) : null,
    salaryDetails: entity.salary.shouldWrite
        ? _salaryToDto(entity.salary)
        : null,
  );

  static EmployeeBankDetails _bankToEntity(EmployeeBankDetailsDto? dto) {
    if (dto == null) return const EmployeeBankDetails();
    return EmployeeBankDetails(
      bankName: dto.bankName,
      bankBranch: dto.bankBranch,
      bankCode: dto.bankCode,
      accountNumber: dto.accountNumber,
      iban: dto.iban,
      swiftCode: dto.swiftCode,
      accountType: dto.accountType,
    );
  }

  static EmployeeBankDetailsDto _bankToDto(EmployeeBankDetails e) =>
      EmployeeBankDetailsDto(
        bankName: e.bankName,
        bankBranch: e.bankBranch,
        bankCode: e.bankCode,
        accountNumber: e.accountNumber,
        iban: e.iban,
        swiftCode: e.swiftCode,
        accountType: e.accountType,
      );

  static Decimal? _dec(String? s) =>
      s == null || s.isEmpty ? null : Decimal.tryParse(s);

  static EmployeeSalaryDetails _salaryToEntity(EmployeeSalaryDetailsDto? dto) {
    if (dto == null) return const EmployeeSalaryDetails();
    return EmployeeSalaryDetails(
      salaryLedgerId: dto.salaryLedgerId,
      advSalaryLedgerId: dto.advSalaryLedgerId,
      basicSalary: _dec(dto.basicSalary),
      da: _dec(dto.da),
      hra: _dec(dto.hra),
      conveyance: _dec(dto.conveyance),
      overtimeHourlyRate: _dec(dto.overtimeHourlyRate),
      overTimePay: _dec(dto.overTimePay),
      monthlyLeave: dto.monthlyLeave,
      weeklyLeave: dto.weeklyLeave,
      annualLeave: dto.annualLeave,
      workingHours: dto.workingHours,
      effectiveFrom: dto.effectiveFrom,
    );
  }

  static EmployeeSalaryDetailsDto _salaryToDto(EmployeeSalaryDetails e) =>
      EmployeeSalaryDetailsDto(
        salaryLedgerId: e.salaryLedgerId,
        advSalaryLedgerId: e.advSalaryLedgerId,
        basicSalary: e.basicSalary?.toString(),
        da: e.da?.toString(),
        hra: e.hra?.toString(),
        conveyance: e.conveyance?.toString(),
        overtimeHourlyRate: e.overtimeHourlyRate?.toString(),
        overTimePay: e.overTimePay?.toString(),
        monthlyLeave: e.monthlyLeave,
        weeklyLeave: e.weeklyLeave,
        annualLeave: e.annualLeave,
        workingHours: e.workingHours,
        effectiveFrom: e.effectiveFrom,
      );
}
