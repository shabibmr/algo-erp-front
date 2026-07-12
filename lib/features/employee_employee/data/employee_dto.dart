import 'package:equatable/equatable.dart';

/// Wire shape of `/employee/employees` matching `employeeDetailsSchema`.
class EmployeeDto extends Equatable {
  const EmployeeDto({
    required this.id,
    required this.name,
    this.employeeCode,
    this.contactId,
    this.fathersName,
    this.dateOfBirth,
    this.gender,
    this.nationality,
    this.maritalStatus,
    this.phone,
    this.designationId,
    this.departmentId,
    this.dateOfJoining,
    this.dateOfLeaving,
    this.biometricId,
    this.highestQualification,
    this.dateOfQualification,
    this.emergencyContactName,
    this.emergencyContactNo,
    this.emergencyContactRelation,
    this.showEmployee,
    this.isActive = true,
    this.bankDetails,
    this.salaryDetails,
  });

  factory EmployeeDto.fromJson(Map<String, dynamic> json) {
    final bankRaw = json['bank_details'] ?? json['bankDetails'];
    // Relation is one-to-many in Prisma; service may return list or single.
    dynamic salaryRaw =
        json['employee_salary_details'] ?? json['salaryDetails'];
    if (salaryRaw is List) {
      salaryRaw = salaryRaw.isNotEmpty ? salaryRaw.first : null;
    }

    return EmployeeDto(
      id: json['id'] as int,
      name: json['Name'] as String? ?? '',
      employeeCode: json['employee_code'] as String?,
      contactId: json['contact_id'] as int?,
      fathersName: json['Fathers_Name'] as String?,
      dateOfBirth: _parseDate(json['Date_of_Birth']),
      gender: json['Gender'] as String?,
      nationality: json['Nationality'] as String?,
      maritalStatus: json['Marital_Status'] as String?,
      phone: json['Phone'] as String?,
      designationId: json['designation_id'] as int?,
      departmentId: json['department_id'] as int?,
      dateOfJoining: _parseDate(json['Date_of_Joining']),
      dateOfLeaving: _parseDate(json['date_of_leaving']),
      biometricId: json['Biometric_ID'] as String?,
      highestQualification: json['Highest_Qualification'] as String?,
      dateOfQualification: _parseDate(json['Date_of_Qualification']),
      emergencyContactName: json['Emergency_Contact_Name'] as String?,
      emergencyContactNo: json['Emergency_Contact_No'] as String?,
      emergencyContactRelation: json['Emergency_Contact_Relation'] as String?,
      showEmployee: json['Show_Employee'] as bool?,
      isActive: json['is_active'] as bool? ?? true,
      bankDetails: bankRaw is Map<String, dynamic>
          ? EmployeeBankDetailsDto.fromJson(bankRaw)
          : null,
      salaryDetails: salaryRaw is Map<String, dynamic>
          ? EmployeeSalaryDetailsDto.fromJson(salaryRaw)
          : null,
    );
  }

  final int id;
  final String name;
  final String? employeeCode;
  final int? contactId;
  final String? fathersName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? nationality;
  final String? maritalStatus;
  final String? phone;
  final int? designationId;
  final int? departmentId;
  final DateTime? dateOfJoining;
  final DateTime? dateOfLeaving;
  final String? biometricId;
  final String? highestQualification;
  final DateTime? dateOfQualification;
  final String? emergencyContactName;
  final String? emergencyContactNo;
  final String? emergencyContactRelation;
  final bool? showEmployee;
  final bool isActive;
  final EmployeeBankDetailsDto? bankDetails;
  final EmployeeSalaryDetailsDto? salaryDetails;

  Map<String, dynamic> toJson() => {
    if (employeeCode != null && employeeCode!.isNotEmpty)
      'employee_code': employeeCode,
    'Name': name,
    'contact_id': contactId,
    'Fathers_Name': fathersName,
    'Date_of_Birth': _dateOnly(dateOfBirth),
    'Gender': gender,
    'Nationality': nationality,
    'Marital_Status': maritalStatus,
    'Phone': phone,
    'designation_id': designationId,
    'department_id': departmentId,
    'Date_of_Joining': _dateOnly(dateOfJoining),
    'date_of_leaving': _dateOnly(dateOfLeaving),
    'Biometric_ID': biometricId,
    'Highest_Qualification': highestQualification,
    'Date_of_Qualification': _dateOnly(dateOfQualification),
    'Emergency_Contact_Name': emergencyContactName,
    'Emergency_Contact_No': emergencyContactNo,
    'Emergency_Contact_Relation': emergencyContactRelation,
    'Show_Employee': showEmployee,
    'is_active': isActive,
    if (bankDetails != null) 'bankDetails': bankDetails!.toJson(),
    if (salaryDetails != null) 'salaryDetails': salaryDetails!.toJson(),
  };

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }

  static String? _dateOnly(DateTime? d) {
    if (d == null) return null;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  List<Object?> get props => [
    id,
    name,
    employeeCode,
    contactId,
    fathersName,
    dateOfBirth,
    gender,
    nationality,
    maritalStatus,
    phone,
    designationId,
    departmentId,
    dateOfJoining,
    dateOfLeaving,
    biometricId,
    highestQualification,
    dateOfQualification,
    emergencyContactName,
    emergencyContactNo,
    emergencyContactRelation,
    showEmployee,
    isActive,
    bankDetails,
    salaryDetails,
  ];
}

class EmployeeBankDetailsDto extends Equatable {
  const EmployeeBankDetailsDto({
    this.bankName,
    this.bankBranch,
    this.bankCode,
    this.accountNumber,
    this.iban,
    this.swiftCode,
    this.accountType,
  });

  factory EmployeeBankDetailsDto.fromJson(Map<String, dynamic> json) =>
      EmployeeBankDetailsDto(
        bankName: json['bank_name'] as String?,
        bankBranch: json['bank_branch'] as String?,
        bankCode: json['bank_code'] as String?,
        accountNumber: json['account_number'] as String?,
        iban: json['iban'] as String?,
        swiftCode: json['swift_code'] as String?,
        accountType: json['account_type'] as String?,
      );

  final String? bankName;
  final String? bankBranch;
  final String? bankCode;
  final String? accountNumber;
  final String? iban;
  final String? swiftCode;
  final String? accountType;

  Map<String, dynamic> toJson() => {
    'bank_name': bankName,
    'bank_branch': bankBranch,
    'bank_code': bankCode,
    'account_number': accountNumber,
    'iban': iban,
    'swift_code': swiftCode,
    'account_type': accountType,
  };

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

class EmployeeSalaryDetailsDto extends Equatable {
  const EmployeeSalaryDetailsDto({
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

  factory EmployeeSalaryDetailsDto.fromJson(Map<String, dynamic> json) {
    String? numStr(dynamic v) => v?.toString();
    return EmployeeSalaryDetailsDto(
      salaryLedgerId: json['salary_ledger_id'] as int?,
      advSalaryLedgerId: json['adv_salary_ledger_id'] as int?,
      basicSalary: numStr(json['Basic_Salary']),
      da: numStr(json['DA']),
      hra: numStr(json['HRA']),
      conveyance: numStr(json['Conveyance']),
      overtimeHourlyRate: numStr(json['overtime_hourly_rate']),
      overTimePay: numStr(json['OverTime_Pay']),
      monthlyLeave: json['Monthly_Leave'] as int?,
      weeklyLeave: json['Weekly_Leave'] as int?,
      annualLeave: json['Annual_Leave'] as int?,
      workingHours: json['Working_Hours'] as int?,
      effectiveFrom: EmployeeDto._parseDate(json['effective_from']),
    );
  }

  final int? salaryLedgerId;
  final int? advSalaryLedgerId;
  final String? basicSalary;
  final String? da;
  final String? hra;
  final String? conveyance;
  final String? overtimeHourlyRate;
  final String? overTimePay;
  final int? monthlyLeave;
  final int? weeklyLeave;
  final int? annualLeave;
  final int? workingHours;
  final DateTime? effectiveFrom;

  Map<String, dynamic> toJson() {
    double? asNum(String? s) => s == null ? null : double.tryParse(s);
    return {
      'salary_ledger_id': salaryLedgerId,
      'adv_salary_ledger_id': advSalaryLedgerId,
      'Basic_Salary': asNum(basicSalary),
      'DA': asNum(da),
      'HRA': asNum(hra),
      'Conveyance': asNum(conveyance),
      'overtime_hourly_rate': asNum(overtimeHourlyRate),
      'OverTime_Pay': asNum(overTimePay),
      'Monthly_Leave': monthlyLeave,
      'Weekly_Leave': weeklyLeave,
      'Annual_Leave': annualLeave,
      'Working_Hours': workingHours,
      'effective_from': EmployeeDto._dateOnly(effectiveFrom),
    };
  }

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
