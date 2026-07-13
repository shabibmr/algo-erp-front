import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/organization_branch/domain/branch.dart';
import 'package:algo_erp_front/features/organization_company/company_profile_di.dart';
import 'package:algo_erp_front/features/organization_company/domain/company_profile.dart';

/// Shared company repo for the companyId FK picker
/// (one instance, not per keystroke).
final _companyRepository = createCompanyProfileRepository(getIt<DioClient>());

/// Branch's manifest. `rbacModule` is `'Branch'` — Organization gates per
/// entity, not per module (`organization.routes.ts`). Soft delete, so the
/// default `hardDelete: false` stands.
final branchManifest = EntityManifest<Branch>(
  id: 'branch',
  label: 'Branch',
  rbacModule: 'Branch',
  resourcePath: '/organization/branches',
  listColumns: [
    FieldSpec<Branch>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      cellValue: (b) => b.name,
    ),
    FieldSpec<Branch>(
      key: 'code',
      label: 'Code',
      type: FieldType.text,
      cellValue: (b) => b.code,
    ),
    FieldSpec<Branch>(
      key: 'companyId',
      label: 'Company',
      type: FieldType.int,
      cellValue: (b) => b.companyId.toString(),
    ),
    FieldSpec<Branch>(
      key: 'address',
      label: 'Address',
      type: FieldType.text,
      cellValue: (b) => b.address ?? '—',
    ),
  ],
  searchFields: const ['name', 'code'],
  formFields: [
    FormFieldSpec<Branch>(
      key: 'name',
      wireKey: 'branch_name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      getValue: (b) => b.name,
      setValue: (b, v) => b.copyWith(name: v as String?),
      // branchSchema: z.string().min(2).max(150)
      validator: (v) {
        final text = v as String?;
        if (text == null || text.isEmpty) return null;
        return text.length < 2 ? 'Must be at least 2 characters' : null;
      },
    ),
    FormFieldSpec<Branch>(
      key: 'code',
      wireKey: 'branch_code',
      label: 'Code',
      type: FieldType.text,
      getValue: (b) => b.code,
      setValue: (b, v) => b.copyWith(code: v as String?),
      // branchSchema: z.string().min(2).max(50)
      validator: (v) {
        final text = v as String?;
        if (text == null || text.isEmpty) return null;
        return text.length < 2 ? 'Must be at least 2 characters' : null;
      },
    ),
    FormFieldSpec<Branch>(
      key: 'companyId',
      wireKey: 'company_id',
      label: 'Company',
      type: FieldType.fk,
      required: true,
      helperText: 'Company this branch belongs to',
      getValue: (b) => b.companyId == 0 ? null : b.companyId,
      setValue: (b, v) {
        final company = v as CompanyProfile?;
        return b.copyWith(companyId: company?.id ?? 0);
      },
      fkSearch: (query) async {
        final result = await _companyRepository.list(
          PageQuery(search: query, limit: 100),
        );
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) {
        final c = item as CompanyProfile;
        final name = c.name?.trim();
        if (name != null && name.isNotEmpty) return name;
        return 'Company #${c.id}';
      },
      fkResolveById: (id) async {
        final result = await _companyRepository.getById(id as int);
        return result.fold((_) => null, (c) => c);
      },
    ),
    FormFieldSpec<Branch>(
      key: 'address',
      wireKey: 'address',
      label: 'Address',
      type: FieldType.text,
      getValue: (b) => b.address,
      setValue: (b, v) => b.copyWith(address: v),
    ),
  ],
  emptyEntity: () => const Branch(id: 0, code: '', name: '', companyId: 0),
);
