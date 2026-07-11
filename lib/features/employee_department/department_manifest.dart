import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/features/employee_department/domain/department.dart';

/// Department's manifest — second manifest after Brand, and the FK target
/// for Designation's hard-case proof. `rbacModule` is `'Employee'`: like
/// Brand's coarse `'Inventory'` gate, the backend gates all of
/// `/employee/**` on the single `'Employee'` string (`feature-inventory.md`
/// §4), not per-sub-entity.
final departmentManifest = EntityManifest<Department>(
  id: 'department',
  label: 'Department',
  rbacModule: 'Employee',
  resourcePath: '/employee/departments',
  listColumns: [
    FieldSpec<Department>(
      key: 'code',
      label: 'Code',
      type: FieldType.text,
      required: true,
      cellValue: (d) => d.code,
    ),
    FieldSpec<Department>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      cellValue: (d) => d.name,
    ),
    FieldSpec<Department>(
      key: 'isActive',
      label: 'Active',
      type: FieldType.bool,
      cellValue: (d) => d.isActive ? 'Yes' : 'No',
    ),
  ],
  searchFields: const ['name', 'code'],
  formFields: [
    FormFieldSpec<Department>(
      key: 'code',
      wireKey: 'dept_code',
      label: 'Code',
      type: FieldType.text,
      required: true,
      getValue: (d) => d.code,
      setValue: (d, v) => d.copyWith(code: v as String?),
    ),
    FormFieldSpec<Department>(
      key: 'name',
      wireKey: 'dept_name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      getValue: (d) => d.name,
      setValue: (d, v) => d.copyWith(name: v as String?),
    ),
    FormFieldSpec<Department>(
      key: 'isActive',
      wireKey: 'is_active',
      label: 'Active',
      type: FieldType.bool,
      getValue: (d) => d.isActive,
      setValue: (d, v) => d.copyWith(isActive: v as bool?),
    ),
  ],
  emptyEntity: () => const Department(id: 0, code: '', name: ''),
);
