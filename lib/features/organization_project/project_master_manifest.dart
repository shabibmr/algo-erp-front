import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:algo_erp_front/features/inventory_godown/godown_di.dart';
import 'package:algo_erp_front/features/organization_address_book/address_book_di.dart';
import 'package:algo_erp_front/features/organization_address_book/domain/address_book.dart';
import 'package:algo_erp_front/features/organization_project/domain/project_master.dart';
import 'package:algo_erp_front/features/organization_project/project_master_di.dart';
import 'package:decimal/decimal.dart';

final _projectRepository = createProjectMasterRepository(getIt<DioClient>());
final _contactRepository = createAddressBookRepository(getIt<DioClient>());
final _ledgerRepository = createLedgerRepository(getIt<DioClient>());
final _godownRepository = createGodownRepository(getIt<DioClient>());

final _isoDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

String? _validateIsoDate(Object? value) {
  final text = value as String?;
  if (text == null || text.isEmpty) return null;
  return _isoDatePattern.hasMatch(text) ? null : 'Must be YYYY-MM-DD';
}

/// Project hierarchy. `rbacModule` is `'ProjectMaster'` (per-entity org gate).
final projectMasterManifest = EntityManifest<ProjectMaster>(
  id: 'project-master',
  label: 'Project',
  rbacModule: 'ProjectMaster',
  resourcePath: projectMasterResourcePath,
  listColumns: [
    FieldSpec<ProjectMaster>(
      key: 'projectId',
      label: 'ID',
      type: FieldType.text,
      required: true,
      cellValue: (p) => p.projectId,
    ),
    FieldSpec<ProjectMaster>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      cellValue: (p) => p.name,
    ),
    FieldSpec<ProjectMaster>(
      key: 'code',
      label: 'Code',
      type: FieldType.text,
      cellValue: (p) => p.projectCode ?? '—',
    ),
    FieldSpec<ProjectMaster>(
      key: 'status',
      label: 'Status',
      type: FieldType.text,
      cellValue: (p) => p.status ?? '—',
    ),
  ],
  searchFields: const ['Project_Name', 'project_code', 'PROJECT_ID'],
  formFields: [
    FormFieldSpec<ProjectMaster>(
      key: 'projectId',
      wireKey: 'PROJECT_ID',
      label: 'Project ID',
      type: FieldType.text,
      required: true,
      helperText: 'Legacy unique key',
      getValue: (p) => p.projectId,
      setValue: (p, v) => p.copyWith(projectId: v as String? ?? ''),
    ),
    FormFieldSpec<ProjectMaster>(
      key: 'name',
      wireKey: 'Project_Name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      getValue: (p) => p.name,
      setValue: (p, v) => p.copyWith(name: v as String? ?? ''),
    ),
    FormFieldSpec<ProjectMaster>(
      key: 'projectCode',
      wireKey: 'project_code',
      label: 'Code',
      type: FieldType.text,
      getValue: (p) => p.projectCode,
      setValue: (p, v) => p.copyWith(projectCode: v as String?),
    ),
    FormFieldSpec<ProjectMaster>(
      key: 'parentProjectMasterId',
      wireKey: 'parent_project_master_id',
      label: 'Parent project',
      type: FieldType.selfFk,
      helperText: 'Optional hierarchy parent (cannot select self)',
      getValue: (p) => p.parentProjectMasterId,
      setValue: (p, v) => p.copyWith(
        parentProjectMasterId: v == null ? null : (v as ProjectMaster).id,
      ),
      fkSearch: (query) async {
        final result = await _projectRepository.list(PageQuery(search: query));
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) {
        final p = item as ProjectMaster;
        final code = p.projectCode;
        return (code == null || code.isEmpty)
            ? '${p.projectId} — ${p.name}'
            : '$code — ${p.name}';
      },
      fkResolveById: (id) async {
        final result = await _projectRepository.getById(id as int);
        return result.fold((_) => null, (p) => p);
      },
    ),
    FormFieldSpec<ProjectMaster>(
      key: 'status',
      wireKey: 'Project_Status',
      label: 'Status',
      type: FieldType.text,
      hintText: 'Active',
      helperText: 'One of: ${ProjectMaster.statuses.join(', ')}',
      getValue: (p) => p.status,
      setValue: (p, v) => p.copyWith(status: v as String?),
      validator: (v) {
        final text = v as String?;
        if (text == null || text.isEmpty) return null;
        return ProjectMaster.statuses.contains(text)
            ? null
            : 'Must be one of: ${ProjectMaster.statuses.join(', ')}';
      },
    ),
    FormFieldSpec<ProjectMaster>(
      key: 'startDate',
      wireKey: 'Start_Date',
      label: 'Start date',
      type: FieldType.text,
      hintText: 'YYYY-MM-DD',
      getValue: (p) => p.startDate,
      setValue: (p, v) => p.copyWith(startDate: v as String?),
      validator: _validateIsoDate,
    ),
    FormFieldSpec<ProjectMaster>(
      key: 'endDate',
      wireKey: 'End_Date',
      label: 'End date',
      type: FieldType.text,
      hintText: 'YYYY-MM-DD',
      getValue: (p) => p.endDate,
      setValue: (p, v) => p.copyWith(endDate: v as String?),
      validator: _validateIsoDate,
    ),
    FormFieldSpec<ProjectMaster>(
      key: 'estimatedValue',
      wireKey: 'Estimated_Value',
      label: 'Estimated value',
      type: FieldType.decimal,
      getValue: (p) => p.estimatedValue,
      setValue: (p, v) => p.copyWith(estimatedValue: v as Decimal?),
    ),
    FormFieldSpec<ProjectMaster>(
      key: 'location',
      wireKey: 'Location',
      label: 'Location',
      type: FieldType.text,
      getValue: (p) => p.location,
      setValue: (p, v) => p.copyWith(location: v as String?),
    ),
    FormFieldSpec<ProjectMaster>(
      key: 'description',
      wireKey: 'Project_Description',
      label: 'Description',
      type: FieldType.text,
      getValue: (p) => p.description,
      setValue: (p, v) => p.copyWith(description: v as String?),
    ),
    FormFieldSpec<ProjectMaster>(
      key: 'detail',
      wireKey: 'Detail',
      label: 'Detail',
      type: FieldType.text,
      getValue: (p) => p.detail,
      setValue: (p, v) => p.copyWith(detail: v as String?),
    ),
    FormFieldSpec<ProjectMaster>(
      key: 'projectOwnerContactId',
      wireKey: 'project_owner_contact_id',
      label: 'Owner contact',
      type: FieldType.fk,
      getValue: (p) => p.projectOwnerContactId,
      setValue: (p, v) => p.copyWith(
        projectOwnerContactId: v == null ? null : (v as AddressBook).id,
      ),
      fkSearch: (query) async {
        final result = await _contactRepository.list(PageQuery(search: query));
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) {
        final c = item as AddressBook;
        return c.name;
      },
      fkResolveById: (id) async {
        final result = await _contactRepository.getById(id as int);
        return result.fold((_) => null, (c) => c);
      },
    ),
    FormFieldSpec<ProjectMaster>(
      key: 'associatedLedgerId',
      wireKey: 'associated_ledger_id',
      label: 'Associated ledger',
      type: FieldType.fk,
      getValue: (p) => p.associatedLedgerId,
      setValue: (p, v) =>
          p.copyWith(associatedLedgerId: v == null ? null : (v as Ledger).id),
      fkSearch: (query) async {
        final result = await _ledgerRepository.list(PageQuery(search: query));
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) {
        final l = item as Ledger;
        return l.name;
      },
      fkResolveById: (id) async {
        final result = await _ledgerRepository.getById(id as int);
        return result.fold((_) => null, (l) => l);
      },
    ),
    FormFieldSpec<ProjectMaster>(
      key: 'godownId',
      wireKey: 'godown_id',
      label: 'Godown',
      type: FieldType.fk,
      getValue: (p) => p.godownId,
      setValue: (p, v) =>
          p.copyWith(godownId: v == null ? null : (v as Godown).id),
      fkSearch: (query) async {
        final result = await _godownRepository.list(PageQuery(search: query));
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) {
        final g = item as Godown;
        return g.name;
      },
      fkResolveById: (id) async {
        final result = await _godownRepository.getById(id as int);
        return result.fold((_) => null, (g) => g);
      },
    ),
    FormFieldSpec<ProjectMaster>(
      key: 'coordinatorEmployeeId',
      wireKey: 'coordinator_employee_id',
      label: 'Coordinator employee id',
      type: FieldType.int,
      helperText: 'Employee master not yet shipped — enter id if known',
      getValue: (p) => p.coordinatorEmployeeId,
      setValue: (p, v) => p.copyWith(coordinatorEmployeeId: v as int?),
    ),
  ],
  emptyEntity: () =>
      const ProjectMaster(id: 0, projectId: '', name: '', status: 'Active'),
  hardDelete: true,
  emptyMessage: 'Add the first project for vouchers and costing.',
);
