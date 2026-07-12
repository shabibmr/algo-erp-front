import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/organization_company/company_profile_di.dart';
import 'package:algo_erp_front/features/organization_company/domain/company_profile.dart';
import 'package:algo_erp_front/features/organization_financial_year/domain/financial_year.dart';

final _companyRepository = createCompanyProfileRepository(getIt<DioClient>());

final _isoDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

String? _validateIsoDate(Object? value) {
  final text = value as String?;
  if (text == null || text.isEmpty) return null;
  return _isoDatePattern.hasMatch(text) ? null : 'Must be YYYY-MM-DD';
}

/// FinancialYear's manifest. `rbacModule` is `'FinancialYear'` — Organization
/// gates per entity (`organization.routes.ts`). `supportsDelete: false`: the
/// backend has no `DELETE /organization/fy/:id` route at all (list/active/
/// create/update only).
final financialYearManifest = EntityManifest<FinancialYear>(
  id: 'financial-year',
  label: 'Financial year',
  rbacModule: 'FinancialYear',
  resourcePath: '/organization/fy',
  listColumns: [
    FieldSpec<FinancialYear>(
      key: 'fyCode',
      label: 'Code',
      type: FieldType.text,
      required: true,
      cellValue: (fy) => fy.fyCode,
    ),
    FieldSpec<FinancialYear>(
      key: 'displayName',
      label: 'Name',
      type: FieldType.text,
      required: true,
      cellValue: (fy) => fy.displayName,
    ),
    FieldSpec<FinancialYear>(
      key: 'status',
      label: 'Status',
      type: FieldType.text,
      cellValue: (fy) => fy.status,
    ),
    FieldSpec<FinancialYear>(
      key: 'isDefault',
      label: 'Default',
      type: FieldType.bool,
      cellValue: (fy) => fy.isDefault ? 'Yes' : 'No',
    ),
  ],
  searchFields: const ['fyCode', 'displayName'],
  formFields: [
    FormFieldSpec<FinancialYear>(
      key: 'fyCode',
      wireKey: 'fy_code',
      label: 'FY code',
      type: FieldType.text,
      required: true,
      // financialYearSchema: z.string().min(4).max(20)
      validator: (v) {
        final text = v as String?;
        if (text == null || text.isEmpty) return null;
        return text.length >= 4 ? null : 'Must be at least 4 characters';
      },
      getValue: (fy) => fy.fyCode,
      setValue: (fy, v) => fy.copyWith(fyCode: v as String?),
    ),
    FormFieldSpec<FinancialYear>(
      key: 'displayName',
      wireKey: 'display_name',
      label: 'Display name',
      type: FieldType.text,
      required: true,
      // financialYearSchema: z.string().min(4).max(50)
      validator: (v) {
        final text = v as String?;
        if (text == null || text.isEmpty) return null;
        return text.length >= 4 ? null : 'Must be at least 4 characters';
      },
      getValue: (fy) => fy.displayName,
      setValue: (fy, v) => fy.copyWith(displayName: v as String?),
    ),
    FormFieldSpec<FinancialYear>(
      key: 'startDate',
      wireKey: 'start_date',
      label: 'Start date',
      type: FieldType.text,
      required: true,
      hintText: 'YYYY-MM-DD',
      validator: _validateIsoDate,
      getValue: (fy) => fy.startDate,
      setValue: (fy, v) => fy.copyWith(startDate: v as String?),
    ),
    FormFieldSpec<FinancialYear>(
      key: 'endDate',
      wireKey: 'end_date',
      label: 'End date',
      type: FieldType.text,
      required: true,
      hintText: 'YYYY-MM-DD',
      validator: _validateIsoDate,
      getValue: (fy) => fy.endDate,
      setValue: (fy, v) => fy.copyWith(endDate: v as String?),
    ),
    FormFieldSpec<FinancialYear>(
      key: 'companyId',
      wireKey: 'company_id',
      label: 'Company',
      type: FieldType.fk,
      required: true,
      getValue: (fy) => fy.companyId == 0 ? null : fy.companyId,
      setValue: (fy, v) {
        final company = v as CompanyProfile?;
        return fy.copyWith(companyId: company?.id ?? 0);
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
    FormFieldSpec<FinancialYear>(
      key: 'status',
      wireKey: 'status',
      label: 'Status',
      type: FieldType.text,
      hintText: 'Open',
      helperText: 'One of: ${FinancialYear.statuses.join(', ')}',
      validator: (v) {
        final text = v as String?;
        if (text == null || text.isEmpty) return null;
        return FinancialYear.statuses.contains(text)
            ? null
            : 'Must be one of: ${FinancialYear.statuses.join(', ')}';
      },
      getValue: (fy) => fy.status,
      setValue: (fy, v) => fy.copyWith(status: v as String?),
    ),
    FormFieldSpec<FinancialYear>(
      key: 'isDefault',
      wireKey: 'is_default',
      label: 'Default financial year',
      type: FieldType.bool,
      getValue: (fy) => fy.isDefault,
      setValue: (fy, v) => fy.copyWith(isDefault: v as bool?),
    ),
  ],
  emptyEntity: () => const FinancialYear(
    id: 0,
    fyCode: '',
    displayName: '',
    startDate: '',
    endDate: '',
    companyId: 0,
  ),
  supportsDelete: false,
);
