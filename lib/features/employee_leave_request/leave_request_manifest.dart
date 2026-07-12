import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/employee_employee/domain/employee.dart';
import 'package:algo_erp_front/features/employee_employee/employee_di.dart';
import 'package:algo_erp_front/features/employee_leave_policy/domain/leave_policy.dart';
import 'package:algo_erp_front/features/employee_leave_policy/leave_policy_di.dart';
import 'package:algo_erp_front/features/employee_leave_request/domain/leave_request.dart';
import 'package:decimal/decimal.dart';

final _employeeRepository = createEmployeeRepository(getIt<DioClient>());
final _leavePolicyRepository = createLeavePolicyRepository(getIt<DioClient>());

/// Leave request list + create. Status transitions use the detail page actions.
final leaveRequestManifest = EntityManifest<LeaveRequest>(
  id: 'leave-request',
  label: 'Leave request',
  rbacModule: 'Employee',
  resourcePath: '/employee/leave-requests',
  supportsUpdate: false,
  supportsDelete: false,
  listColumns: [
    FieldSpec<LeaveRequest>(
      key: 'employee',
      label: 'Employee',
      type: FieldType.text,
      cellValue: (r) => r.employeeName ?? '#${r.employeeId}',
    ),
    FieldSpec<LeaveRequest>(
      key: 'policy',
      label: 'Policy',
      type: FieldType.text,
      cellValue: (r) => r.policyName ?? '#${r.leavePolicyId}',
    ),
    FieldSpec<LeaveRequest>(
      key: 'from',
      label: 'From',
      type: FieldType.dateTime,
      cellValue: (r) => r.fromDate.toIso8601String().split('T').first,
    ),
    FieldSpec<LeaveRequest>(
      key: 'to',
      label: 'To',
      type: FieldType.dateTime,
      cellValue: (r) => r.toDate.toIso8601String().split('T').first,
    ),
    FieldSpec<LeaveRequest>(
      key: 'days',
      label: 'Days',
      type: FieldType.decimal,
      cellValue: (r) => r.numberOfDays.toString(),
    ),
    FieldSpec<LeaveRequest>(
      key: 'status',
      label: 'Status',
      type: FieldType.text,
      cellValue: (r) => r.status,
    ),
  ],
  formFields: [
    FormFieldSpec<LeaveRequest>(
      key: 'employeeId',
      wireKey: 'employee_id',
      label: 'Employee',
      type: FieldType.fk,
      required: true,
      getValue: (r) => r.employeeId == 0 ? null : r.employeeId,
      setValue: (r, v) =>
          r.copyWith(employeeId: v == null ? 0 : (v as Employee).id),
      fkSearch: (query) async {
        final result = await _employeeRepository.list(PageQuery(search: query));
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) {
        final e = item as Employee;
        final code = e.code;
        return (code == null || code.isEmpty) ? e.name : '$code — ${e.name}';
      },
      fkResolveById: (id) async {
        final result = await _employeeRepository.getById(id as int);
        return result.fold((_) => null, (e) => e);
      },
    ),
    FormFieldSpec<LeaveRequest>(
      key: 'leavePolicyId',
      wireKey: 'leave_policy_id',
      label: 'Leave policy',
      type: FieldType.fk,
      required: true,
      getValue: (r) => r.leavePolicyId == 0 ? null : r.leavePolicyId,
      setValue: (r, v) =>
          r.copyWith(leavePolicyId: v == null ? 0 : (v as LeavePolicy).id),
      fkSearch: (query) async {
        final result = await _leavePolicyRepository.list(
          PageQuery(search: query),
        );
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) => (item as LeavePolicy).displayName,
      fkResolveById: (id) async {
        final result = await _leavePolicyRepository.getById(id as int);
        return result.fold((_) => null, (p) => p);
      },
    ),
    FormFieldSpec<LeaveRequest>(
      key: 'fromDate',
      wireKey: 'from_date',
      label: 'From date',
      type: FieldType.dateTime,
      required: true,
      getValue: (r) => r.fromDate,
      setValue: (r, v) => r.copyWith(fromDate: v as DateTime?),
    ),
    FormFieldSpec<LeaveRequest>(
      key: 'toDate',
      wireKey: 'to_date',
      label: 'To date',
      type: FieldType.dateTime,
      required: true,
      getValue: (r) => r.toDate,
      setValue: (r, v) => r.copyWith(toDate: v as DateTime?),
    ),
    FormFieldSpec<LeaveRequest>(
      key: 'numberOfDays',
      wireKey: 'number_of_days',
      label: 'Number of days',
      type: FieldType.decimal,
      required: true,
      getValue: (r) => r.numberOfDays,
      setValue: (r, v) =>
          r.copyWith(numberOfDays: v as Decimal? ?? Decimal.one),
    ),
    FormFieldSpec<LeaveRequest>(
      key: 'reason',
      wireKey: 'reason',
      label: 'Reason',
      type: FieldType.text,
      getValue: (r) => r.reason,
      setValue: (r, v) => r.copyWith(reason: v as String?),
    ),
  ],
  emptyEntity: () => LeaveRequest(
    id: 0,
    employeeId: 0,
    leavePolicyId: 0,
    fromDate: DateTime.now(),
    toDate: DateTime.now(),
    numberOfDays: Decimal.one,
  ),
);
