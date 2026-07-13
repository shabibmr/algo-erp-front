import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/employee_department/department_di.dart';
import 'package:algo_erp_front/features/employee_department/domain/department.dart';
import 'package:algo_erp_front/features/employee_designation/designation_di.dart';
import 'package:algo_erp_front/features/employee_designation/domain/designation.dart';
import 'package:algo_erp_front/features/employee_employee/domain/employee.dart';
import 'package:algo_erp_front/features/organization_address_book/address_book_di.dart';
import 'package:algo_erp_front/features/organization_address_book/domain/address_book.dart';

final _departmentRepository = createDepartmentRepository(getIt<DioClient>());
final _designationRepository = createDesignationRepository(getIt<DioClient>());
final _addressBookRepository = createAddressBookRepository(getIt<DioClient>());

/// Employee master. List uses this manifest; create/edit uses the tabbed form
/// (Core + Bank + Salary) in `employee_form_page.dart`.
final employeeManifest = EntityManifest<Employee>(
  id: 'employee',
  label: 'Employee',
  rbacModule: 'Employee',
  resourcePath: '/employee/employees',
  listColumns: [
    FieldSpec<Employee>(
      key: 'code',
      label: 'Code',
      type: FieldType.text,
      cellValue: (e) => e.code ?? '—',
    ),
    FieldSpec<Employee>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      cellValue: (e) => e.name,
    ),
    FieldSpec<Employee>(
      key: 'phone',
      label: 'Phone',
      type: FieldType.text,
      cellValue: (e) => e.phone ?? '—',
    ),
    FieldSpec<Employee>(
      key: 'isActive',
      label: 'Active',
      type: FieldType.bool,
      cellValue: (e) => e.isActive ? 'Yes' : 'No',
    ),
  ],
  searchFields: const ['Name', 'employee_code', 'Phone'],
  formFields: [
    FormFieldSpec<Employee>(
      key: 'code',
      wireKey: 'employee_code',
      label: 'Code',
      type: FieldType.text,
      getValue: (e) => e.code,
      setValue: (e, v) => e.copyWith(code: v as String?),
    ),
    FormFieldSpec<Employee>(
      key: 'name',
      wireKey: 'Name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      getValue: (e) => e.name,
      setValue: (e, v) => e.copyWith(name: v as String?),
    ),
    FormFieldSpec<Employee>(
      key: 'contactId',
      wireKey: 'contact_id',
      label: 'Contact',
      type: FieldType.fk,
      getValue: (e) => e.contactId,
      setValue: (e, v) =>
          e.copyWith(contactId: v == null ? null : (v as AddressBook).id),
      fkSearch: (query) async {
        final result = await _addressBookRepository.list(
          PageQuery(search: query),
        );
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) => (item as AddressBook).name,
      fkResolveById: (id) async {
        final result = await _addressBookRepository.getById(id as int);
        return result.fold((_) => null, (c) => c);
      },
    ),
    FormFieldSpec<Employee>(
      key: 'departmentId',
      wireKey: 'department_id',
      label: 'Department',
      type: FieldType.fk,
      getValue: (e) => e.departmentId,
      setValue: (e, v) =>
          e.copyWith(departmentId: v == null ? null : (v as Department).id),
      fkSearch: (query) async {
        final result = await _departmentRepository.list(
          PageQuery(search: query),
        );
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) => (item as Department).name,
      fkResolveById: (id) async {
        final result = await _departmentRepository.getById(id as int);
        return result.fold((_) => null, (d) => d);
      },
    ),
    FormFieldSpec<Employee>(
      key: 'designationId',
      wireKey: 'designation_id',
      label: 'Designation',
      type: FieldType.fk,
      getValue: (e) => e.designationId,
      setValue: (e, v) =>
          e.copyWith(designationId: v == null ? null : (v as Designation).id),
      fkSearch: (query) async {
        final result = await _designationRepository.list(
          PageQuery(search: query),
        );
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) => (item as Designation).name,
      fkResolveById: (id) async {
        final result = await _designationRepository.getById(id as int);
        return result.fold((_) => null, (d) => d);
      },
    ),
    FormFieldSpec<Employee>(
      key: 'gender',
      wireKey: 'Gender',
      label: 'Gender',
      type: FieldType.text,
      helperText: Employee.genders.join(', '),
      getValue: (e) => e.gender,
      setValue: (e, v) => e.copyWith(gender: v as String?),
    ),
    FormFieldSpec<Employee>(
      key: 'maritalStatus',
      wireKey: 'Marital_Status',
      label: 'Marital status',
      type: FieldType.text,
      helperText: Employee.maritalStatuses.join(', '),
      getValue: (e) => e.maritalStatus,
      setValue: (e, v) => e.copyWith(maritalStatus: v as String?),
    ),
    FormFieldSpec<Employee>(
      key: 'nationality',
      wireKey: 'Nationality',
      label: 'Nationality',
      type: FieldType.text,
      getValue: (e) => e.nationality,
      setValue: (e, v) => e.copyWith(nationality: v as String?),
    ),
    FormFieldSpec<Employee>(
      key: 'phone',
      wireKey: 'Phone',
      label: 'Phone',
      type: FieldType.text,
      getValue: (e) => e.phone,
      setValue: (e, v) => e.copyWith(phone: v as String?),
    ),
    FormFieldSpec<Employee>(
      key: 'fathersName',
      wireKey: 'Fathers_Name',
      label: "Father's name",
      type: FieldType.text,
      getValue: (e) => e.fathersName,
      setValue: (e, v) => e.copyWith(fathersName: v as String?),
    ),
    FormFieldSpec<Employee>(
      key: 'dateOfBirth',
      wireKey: 'Date_of_Birth',
      label: 'Date of birth',
      type: FieldType.dateTime,
      getValue: (e) => e.dateOfBirth,
      setValue: (e, v) => e.copyWith(dateOfBirth: v as DateTime?),
    ),
    FormFieldSpec<Employee>(
      key: 'dateOfJoining',
      wireKey: 'Date_of_Joining',
      label: 'Date of joining',
      type: FieldType.dateTime,
      getValue: (e) => e.dateOfJoining,
      setValue: (e, v) => e.copyWith(dateOfJoining: v as DateTime?),
    ),
    FormFieldSpec<Employee>(
      key: 'dateOfLeaving',
      wireKey: 'date_of_leaving',
      label: 'Date of leaving',
      type: FieldType.dateTime,
      getValue: (e) => e.dateOfLeaving,
      setValue: (e, v) => e.copyWith(dateOfLeaving: v as DateTime?),
    ),
    FormFieldSpec<Employee>(
      key: 'biometricId',
      wireKey: 'Biometric_ID',
      label: 'Biometric ID',
      type: FieldType.text,
      getValue: (e) => e.biometricId,
      setValue: (e, v) => e.copyWith(biometricId: v as String?),
    ),
    FormFieldSpec<Employee>(
      key: 'highestQualification',
      wireKey: 'Highest_Qualification',
      label: 'Highest qualification',
      type: FieldType.text,
      getValue: (e) => e.highestQualification,
      setValue: (e, v) => e.copyWith(highestQualification: v as String?),
    ),
    FormFieldSpec<Employee>(
      key: 'dateOfQualification',
      wireKey: 'Date_of_Qualification',
      label: 'Date of qualification',
      type: FieldType.dateTime,
      getValue: (e) => e.dateOfQualification,
      setValue: (e, v) => e.copyWith(dateOfQualification: v as DateTime?),
    ),
    FormFieldSpec<Employee>(
      key: 'emergencyContactName',
      wireKey: 'Emergency_Contact_Name',
      label: 'Emergency contact name',
      type: FieldType.text,
      getValue: (e) => e.emergencyContactName,
      setValue: (e, v) => e.copyWith(emergencyContactName: v as String?),
    ),
    FormFieldSpec<Employee>(
      key: 'emergencyContactNo',
      wireKey: 'Emergency_Contact_No',
      label: 'Emergency contact no',
      type: FieldType.text,
      getValue: (e) => e.emergencyContactNo,
      setValue: (e, v) => e.copyWith(emergencyContactNo: v as String?),
    ),
    FormFieldSpec<Employee>(
      key: 'emergencyContactRelation',
      wireKey: 'Emergency_Contact_Relation',
      label: 'Emergency contact relation',
      type: FieldType.text,
      getValue: (e) => e.emergencyContactRelation,
      setValue: (e, v) => e.copyWith(emergencyContactRelation: v as String?),
    ),
    FormFieldSpec<Employee>(
      key: 'showEmployee',
      wireKey: 'Show_Employee',
      label: 'Show employee',
      type: FieldType.bool,
      getValue: (e) => e.showEmployee ?? true,
      setValue: (e, v) => e.copyWith(showEmployee: v as bool?),
    ),
    FormFieldSpec<Employee>(
      key: 'isActive',
      wireKey: 'is_active',
      label: 'Active',
      type: FieldType.bool,
      getValue: (e) => e.isActive,
      setValue: (e, v) => e.copyWith(isActive: v as bool?),
    ),
  ],
  emptyEntity: () => const Employee(id: 0, name: ''),
);
