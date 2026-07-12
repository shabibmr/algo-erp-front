import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/features/employee_leave_policy/domain/leave_policy.dart';

/// Create-only leave policy (backend has no PUT/DELETE/GET-by-id).
final leavePolicyManifest = EntityManifest<LeavePolicy>(
  id: 'leave-policy',
  label: 'Leave policy',
  rbacModule: 'Employee',
  resourcePath: '/employee/leave/policies',
  supportsUpdate: false,
  supportsDelete: false,
  listColumns: [
    FieldSpec<LeavePolicy>(
      key: 'leaveType',
      label: 'Type',
      type: FieldType.text,
      cellValue: (p) => p.leaveType,
    ),
    FieldSpec<LeavePolicy>(
      key: 'displayName',
      label: 'Name',
      type: FieldType.text,
      required: true,
      cellValue: (p) => p.displayName,
    ),
    FieldSpec<LeavePolicy>(
      key: 'maxDays',
      label: 'Max days/yr',
      type: FieldType.int,
      cellValue: (p) => p.maxDaysPerYear.toString(),
    ),
    FieldSpec<LeavePolicy>(
      key: 'isPaid',
      label: 'Paid',
      type: FieldType.bool,
      cellValue: (p) => p.isPaid ? 'Yes' : 'No',
    ),
    FieldSpec<LeavePolicy>(
      key: 'isActive',
      label: 'Active',
      type: FieldType.bool,
      cellValue: (p) => p.isActive ? 'Yes' : 'No',
    ),
  ],
  searchFields: const ['leave_type', 'display_name'],
  formFields: [
    FormFieldSpec<LeavePolicy>(
      key: 'leaveType',
      wireKey: 'leave_type',
      label: 'Leave type',
      type: FieldType.text,
      required: true,
      helperText: LeavePolicy.leaveTypes.join(', '),
      getValue: (p) => p.leaveType,
      setValue: (p, v) => p.copyWith(leaveType: v as String?),
      validator: (v) {
        final s = v as String?;
        if (s == null || s.isEmpty) return 'Leave type is required';
        if (!LeavePolicy.leaveTypes.contains(s)) {
          return 'Must be one of: ${LeavePolicy.leaveTypes.join(', ')}';
        }
        return null;
      },
    ),
    FormFieldSpec<LeavePolicy>(
      key: 'displayName',
      wireKey: 'display_name',
      label: 'Display name',
      type: FieldType.text,
      required: true,
      getValue: (p) => p.displayName,
      setValue: (p, v) => p.copyWith(displayName: v as String?),
    ),
    FormFieldSpec<LeavePolicy>(
      key: 'maxDaysPerYear',
      wireKey: 'max_days_per_year',
      label: 'Max days per year',
      type: FieldType.int,
      getValue: (p) => p.maxDaysPerYear,
      setValue: (p, v) => p.copyWith(maxDaysPerYear: v as int? ?? 0),
    ),
    FormFieldSpec<LeavePolicy>(
      key: 'maxDaysPerRequest',
      wireKey: 'max_days_per_request',
      label: 'Max days per request',
      type: FieldType.int,
      getValue: (p) => p.maxDaysPerRequest,
      setValue: (p, v) => p.copyWith(maxDaysPerRequest: v as int?),
    ),
    FormFieldSpec<LeavePolicy>(
      key: 'carryForwardLimit',
      wireKey: 'carry_forward_limit',
      label: 'Carry-forward limit',
      type: FieldType.int,
      getValue: (p) => p.carryForwardLimit,
      setValue: (p, v) => p.copyWith(carryForwardLimit: v as int? ?? 0),
    ),
    FormFieldSpec<LeavePolicy>(
      key: 'requiresApproval',
      wireKey: 'requires_approval',
      label: 'Requires approval',
      type: FieldType.bool,
      getValue: (p) => p.requiresApproval,
      setValue: (p, v) => p.copyWith(requiresApproval: v as bool?),
    ),
    FormFieldSpec<LeavePolicy>(
      key: 'isPaid',
      wireKey: 'is_paid',
      label: 'Paid leave',
      type: FieldType.bool,
      getValue: (p) => p.isPaid,
      setValue: (p, v) => p.copyWith(isPaid: v as bool?),
    ),
    FormFieldSpec<LeavePolicy>(
      key: 'applicableGender',
      wireKey: 'applicable_gender',
      label: 'Applicable gender',
      type: FieldType.text,
      helperText: 'Optional: Male / Female / Other',
      getValue: (p) => p.applicableGender,
      setValue: (p, v) => p.copyWith(applicableGender: v as String?),
    ),
    FormFieldSpec<LeavePolicy>(
      key: 'isActive',
      wireKey: 'is_active',
      label: 'Active',
      type: FieldType.bool,
      getValue: (p) => p.isActive,
      setValue: (p, v) => p.copyWith(isActive: v as bool?),
    ),
  ],
  emptyEntity: () =>
      const LeavePolicy(id: 0, leaveType: 'Annual', displayName: ''),
);
