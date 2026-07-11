import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/employee_department/department_di.dart';
import 'package:algo_erp_front/features/employee_department/domain/department.dart';
import 'package:algo_erp_front/features/employee_designation/domain/designation.dart';

/// Lazily built once and reused across every search/resolve call — avoids
/// constructing a fresh `RemoteRepository` per keystroke in the FK picker.
final _departmentRepository = createDepartmentRepository(getIt<DioClient>());

/// Designation's manifest — the EMR's first real use of `FieldType.fk`
/// (`department_id`, a hard FK to `Department`, confirmed against
/// `docs/feature-inventory.md` §4 to have **no** self-FK, unlike
/// `Department` itself). `rbacModule` is `'Employee'`, matching
/// `departmentManifest`'s coarse module gate.
final designationManifest = EntityManifest<Designation>(
  id: 'designation',
  label: 'Designation',
  rbacModule: 'Employee',
  resourcePath: '/employee/designations',
  listColumns: [
    FieldSpec<Designation>(
      key: 'code',
      label: 'Code',
      type: FieldType.text,
      required: true,
      cellValue: (d) => d.code,
    ),
    FieldSpec<Designation>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      cellValue: (d) => d.name,
    ),
    FieldSpec<Designation>(
      key: 'isActive',
      label: 'Active',
      type: FieldType.bool,
      cellValue: (d) => d.isActive ? 'Yes' : 'No',
    ),
  ],
  searchFields: const ['name', 'code'],
  formFields: [
    FormFieldSpec<Designation>(
      key: 'code',
      wireKey: 'designation_code',
      label: 'Code',
      type: FieldType.text,
      required: true,
      getValue: (d) => d.code,
      setValue: (d, v) => d.copyWith(code: v as String?),
    ),
    FormFieldSpec<Designation>(
      key: 'name',
      wireKey: 'designation_name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      getValue: (d) => d.name,
      setValue: (d, v) => d.copyWith(name: v as String?),
    ),
    FormFieldSpec<Designation>(
      key: 'departmentId',
      wireKey: 'department_id',
      label: 'Department',
      type: FieldType.fk,
      required: true,
      getValue: (d) => d.departmentId,
      setValue: (d, v) => d.copyWith(departmentId: (v! as Department).id),
      fkSearch: (query) async {
        final result =
            await _departmentRepository.list(PageQuery(search: query));
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) => (item as Department).name,
      fkResolveById: (id) async {
        final result = await _departmentRepository.getById(id as int);
        return result.fold((_) => null, (d) => d);
      },
    ),
    FormFieldSpec<Designation>(
      key: 'isActive',
      wireKey: 'is_active',
      label: 'Active',
      type: FieldType.bool,
      getValue: (d) => d.isActive,
      setValue: (d, v) => d.copyWith(isActive: v as bool?),
    ),
  ],
  emptyEntity: () =>
      const Designation(id: 0, code: '', name: '', departmentId: 0),
);
