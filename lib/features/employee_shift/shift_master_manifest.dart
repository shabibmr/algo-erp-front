import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/features/employee_shift/domain/shift_master.dart';
import 'package:decimal/decimal.dart';

/// Create-only shift master (backend has no PUT/DELETE/GET-by-id).
final shiftMasterManifest = EntityManifest<ShiftMaster>(
  id: 'shift-master',
  label: 'Shift',
  rbacModule: 'Employee',
  resourcePath: '/employee/shifts',
  supportsUpdate: false,
  supportsDelete: false,
  listColumns: [
    FieldSpec<ShiftMaster>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      cellValue: (s) => s.name,
    ),
    FieldSpec<ShiftMaster>(
      key: 'code',
      label: 'Code',
      type: FieldType.text,
      cellValue: (s) => s.code,
    ),
    FieldSpec<ShiftMaster>(
      key: 'start',
      label: 'Start',
      type: FieldType.text,
      cellValue: (s) => s.startTime,
    ),
    FieldSpec<ShiftMaster>(
      key: 'end',
      label: 'End',
      type: FieldType.text,
      cellValue: (s) => s.endTime,
    ),
    FieldSpec<ShiftMaster>(
      key: 'hours',
      label: 'Hours',
      type: FieldType.decimal,
      cellValue: (s) => s.workingHours.toString(),
    ),
  ],
  searchFields: const ['shift_code', 'shift_name'],
  formFields: [
    FormFieldSpec<ShiftMaster>(
      key: 'name',
      wireKey: 'shift_name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      getValue: (s) => s.name,
      setValue: (s, v) => s.copyWith(name: v as String?),
    ),
    FormFieldSpec<ShiftMaster>(
      key: 'code',
      wireKey: 'shift_code',
      label: 'Code',
      type: FieldType.text,
      getValue: (s) => s.code,
      setValue: (s, v) => s.copyWith(code: v as String?),
    ),
    FormFieldSpec<ShiftMaster>(
      key: 'startTime',
      wireKey: 'start_time',
      label: 'Start time',
      type: FieldType.text,
      required: true,
      helperText: 'HH:mm:ss',
      hintText: '09:00:00',
      getValue: (s) => s.startTime,
      setValue: (s, v) => s.copyWith(startTime: v as String?),
      validator: (v) {
        final s = v as String?;
        if (s == null || s.isEmpty) return 'Required';
        final ok = RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(s);
        return ok ? null : 'Use HH:mm:ss';
      },
    ),
    FormFieldSpec<ShiftMaster>(
      key: 'endTime',
      wireKey: 'end_time',
      label: 'End time',
      type: FieldType.text,
      required: true,
      helperText: 'HH:mm:ss',
      hintText: '18:00:00',
      getValue: (s) => s.endTime,
      setValue: (s, v) => s.copyWith(endTime: v as String?),
      validator: (v) {
        final s = v as String?;
        if (s == null || s.isEmpty) return 'Required';
        final ok = RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(s);
        return ok ? null : 'Use HH:mm:ss';
      },
    ),
    FormFieldSpec<ShiftMaster>(
      key: 'workingHours',
      wireKey: 'working_hours',
      label: 'Working hours',
      type: FieldType.decimal,
      required: true,
      getValue: (s) => s.workingHours,
      setValue: (s, v) =>
          s.copyWith(workingHours: v as Decimal? ?? Decimal.zero),
    ),
    FormFieldSpec<ShiftMaster>(
      key: 'breakMinutes',
      wireKey: 'break_minutes',
      label: 'Break minutes',
      type: FieldType.int,
      getValue: (s) => s.breakMinutes,
      setValue: (s, v) => s.copyWith(breakMinutes: v as int? ?? 0),
    ),
    FormFieldSpec<ShiftMaster>(
      key: 'isNightShift',
      wireKey: 'is_night_shift',
      label: 'Night shift',
      type: FieldType.bool,
      getValue: (s) => s.isNightShift,
      setValue: (s, v) => s.copyWith(isNightShift: v as bool?),
    ),
    FormFieldSpec<ShiftMaster>(
      key: 'isActive',
      wireKey: 'is_active',
      label: 'Active',
      type: FieldType.bool,
      getValue: (s) => s.isActive,
      setValue: (s, v) => s.copyWith(isActive: v as bool?),
    ),
  ],
  emptyEntity: () => ShiftMaster(
    id: 0,
    code: '',
    name: '',
    startTime: '09:00:00',
    endTime: '18:00:00',
    workingHours: Decimal.fromInt(8),
  ),
);
