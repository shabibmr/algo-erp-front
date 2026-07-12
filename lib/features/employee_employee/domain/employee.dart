import 'package:algo_erp_front/features/employee_employee/domain/employee_extensions.dart';
import 'package:equatable/equatable.dart';

const _unset = Object();

/// Employee master (`employee_details`) with nested bank + salary extensions.
///
/// Soft-deleted via `is_active`. Document fields on the main row are legacy
/// duplicates of `employeedocuments` — managed via the documents API, not this
/// form (see Sprint F notes).
class Employee extends Equatable {
  const Employee({
    required this.id,
    required this.name,
    this.code,
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
    this.bank = const EmployeeBankDetails(),
    this.salary = const EmployeeSalaryDetails(),
  });

  static const genders = ['Male', 'Female', 'Other'];
  static const maritalStatuses = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
  ];

  final int id;
  final String name;
  final String? code;
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
  final EmployeeBankDetails bank;
  final EmployeeSalaryDetails salary;

  Employee copyWith({
    int? id,
    String? name,
    Object? code = _unset,
    Object? contactId = _unset,
    Object? fathersName = _unset,
    Object? dateOfBirth = _unset,
    Object? gender = _unset,
    Object? nationality = _unset,
    Object? maritalStatus = _unset,
    Object? phone = _unset,
    Object? designationId = _unset,
    Object? departmentId = _unset,
    Object? dateOfJoining = _unset,
    Object? dateOfLeaving = _unset,
    Object? biometricId = _unset,
    Object? highestQualification = _unset,
    Object? dateOfQualification = _unset,
    Object? emergencyContactName = _unset,
    Object? emergencyContactNo = _unset,
    Object? emergencyContactRelation = _unset,
    Object? showEmployee = _unset,
    bool? isActive,
    EmployeeBankDetails? bank,
    EmployeeSalaryDetails? salary,
  }) => Employee(
    id: id ?? this.id,
    name: name ?? this.name,
    code: identical(code, _unset) ? this.code : code as String?,
    contactId: identical(contactId, _unset)
        ? this.contactId
        : contactId as int?,
    fathersName: identical(fathersName, _unset)
        ? this.fathersName
        : fathersName as String?,
    dateOfBirth: identical(dateOfBirth, _unset)
        ? this.dateOfBirth
        : dateOfBirth as DateTime?,
    gender: identical(gender, _unset) ? this.gender : gender as String?,
    nationality: identical(nationality, _unset)
        ? this.nationality
        : nationality as String?,
    maritalStatus: identical(maritalStatus, _unset)
        ? this.maritalStatus
        : maritalStatus as String?,
    phone: identical(phone, _unset) ? this.phone : phone as String?,
    designationId: identical(designationId, _unset)
        ? this.designationId
        : designationId as int?,
    departmentId: identical(departmentId, _unset)
        ? this.departmentId
        : departmentId as int?,
    dateOfJoining: identical(dateOfJoining, _unset)
        ? this.dateOfJoining
        : dateOfJoining as DateTime?,
    dateOfLeaving: identical(dateOfLeaving, _unset)
        ? this.dateOfLeaving
        : dateOfLeaving as DateTime?,
    biometricId: identical(biometricId, _unset)
        ? this.biometricId
        : biometricId as String?,
    highestQualification: identical(highestQualification, _unset)
        ? this.highestQualification
        : highestQualification as String?,
    dateOfQualification: identical(dateOfQualification, _unset)
        ? this.dateOfQualification
        : dateOfQualification as DateTime?,
    emergencyContactName: identical(emergencyContactName, _unset)
        ? this.emergencyContactName
        : emergencyContactName as String?,
    emergencyContactNo: identical(emergencyContactNo, _unset)
        ? this.emergencyContactNo
        : emergencyContactNo as String?,
    emergencyContactRelation: identical(emergencyContactRelation, _unset)
        ? this.emergencyContactRelation
        : emergencyContactRelation as String?,
    showEmployee: identical(showEmployee, _unset)
        ? this.showEmployee
        : showEmployee as bool?,
    isActive: isActive ?? this.isActive,
    bank: bank ?? this.bank,
    salary: salary ?? this.salary,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    code,
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
    bank,
    salary,
  ];
}
