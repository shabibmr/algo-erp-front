import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/organization_branch/branch_di.dart';
import 'package:algo_erp_front/features/organization_branch/domain/branch.dart';
import 'package:algo_erp_front/features/organization_financial_year/domain/financial_year.dart';
import 'package:algo_erp_front/features/organization_financial_year/financial_year_di.dart';
import 'package:algo_erp_front/features/organization_voucher_series/domain/voucher_series.dart';
import 'package:algo_erp_front/features/organization_voucher_series/voucher_series_di.dart';

final _branchRepository = createBranchRepository(getIt<DioClient>());
final _financialYearRepository = createFinancialYearRepository(
  getIt<DioClient>(),
);

/// Voucher series master — toggles optional approval via requireApproval.
final voucherSeriesManifest = EntityManifest<VoucherSeries>(
  id: 'voucher-series',
  label: 'Voucher series',
  rbacModule: 'VoucherSeries',
  resourcePath: voucherSeriesResourcePath,
  listColumns: [
    FieldSpec<VoucherSeries>(
      key: 'voucherType',
      label: 'Type',
      type: FieldType.text,
      cellValue: (s) => s.voucherType,
    ),
    FieldSpec<VoucherSeries>(
      key: 'prefix',
      label: 'Prefix',
      type: FieldType.text,
      required: true,
      cellValue: (s) => s.prefix,
    ),
    FieldSpec<VoucherSeries>(
      key: 'displayName',
      label: 'Name',
      type: FieldType.text,
      required: true,
      cellValue: (s) => s.displayName,
    ),
    FieldSpec<VoucherSeries>(
      key: 'requireApproval',
      label: 'Approval',
      type: FieldType.bool,
      cellValue: (s) => s.requireApproval ? 'Required' : 'Off',
    ),
    FieldSpec<VoucherSeries>(
      key: 'isDefault',
      label: 'Default',
      type: FieldType.bool,
      cellValue: (s) => s.isDefault ? 'Yes' : 'No',
    ),
  ],
  searchFields: const ['display_name', 'prefix', 'voucher_type'],
  formFields: [
    FormFieldSpec<VoucherSeries>(
      key: 'voucherType',
      wireKey: 'voucher_type',
      label: 'Voucher type',
      type: FieldType.text,
      required: true,
      helperText: VoucherSeries.voucherTypes.join(', '),
      hintText: 'SalesInvoice',
      getValue: (s) => s.voucherType,
      setValue: (s, v) => s.copyWith(voucherType: v as String?),
    ),
    FormFieldSpec<VoucherSeries>(
      key: 'prefix',
      wireKey: 'prefix',
      label: 'Prefix',
      type: FieldType.text,
      required: true,
      hintText: 'SI',
      getValue: (s) => s.prefix,
      setValue: (s, v) => s.copyWith(prefix: v as String?),
    ),
    FormFieldSpec<VoucherSeries>(
      key: 'displayName',
      wireKey: 'display_name',
      label: 'Display name',
      type: FieldType.text,
      required: true,
      getValue: (s) => s.displayName,
      setValue: (s, v) => s.copyWith(displayName: v as String?),
    ),
    FormFieldSpec<VoucherSeries>(
      key: 'companyId',
      wireKey: 'company_id',
      label: 'Company id',
      type: FieldType.int,
      required: true,
      helperText: 'CompanyProfile picker deferred — enter company id',
      getValue: (s) => s.companyId,
      setValue: (s, v) => s.copyWith(companyId: v as int? ?? 0),
    ),
    FormFieldSpec<VoucherSeries>(
      key: 'branchId',
      wireKey: 'branch_id',
      label: 'Branch',
      type: FieldType.fk,
      getValue: (s) => s.branchId,
      setValue: (s, v) =>
          s.copyWith(branchId: v == null ? null : (v as Branch).id),
      fkSearch: (query) async {
        final result = await _branchRepository.list(PageQuery(search: query));
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) {
        final b = item as Branch;
        return '${b.code} — ${b.name}';
      },
      fkResolveById: (id) async {
        final result = await _branchRepository.getById(id as int);
        return result.fold((_) => null, (b) => b);
      },
    ),
    FormFieldSpec<VoucherSeries>(
      key: 'financialYearId',
      wireKey: 'financial_year_id',
      label: 'Financial year',
      type: FieldType.fk,
      getValue: (s) => s.financialYearId,
      setValue: (s, v) => s.copyWith(
        financialYearId: v == null ? null : (v as FinancialYear).id,
      ),
      fkSearch: (query) async {
        final result = await _financialYearRepository.list(
          PageQuery(search: query),
        );
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) {
        final fy = item as FinancialYear;
        return '${fy.fyCode} — ${fy.displayName}';
      },
      fkResolveById: (id) async {
        final result = await _financialYearRepository.getById(id as int);
        return result.fold((_) => null, (fy) => fy);
      },
    ),
    FormFieldSpec<VoucherSeries>(
      key: 'numberLength',
      wireKey: 'number_length',
      label: 'Number length',
      type: FieldType.int,
      getValue: (s) => s.numberLength,
      setValue: (s, v) => s.copyWith(numberLength: v as int? ?? 5),
    ),
    FormFieldSpec<VoucherSeries>(
      key: 'prefixSeparator',
      wireKey: 'prefix_separator',
      label: 'Prefix separator',
      type: FieldType.text,
      getValue: (s) => s.prefixSeparator,
      setValue: (s, v) => s.copyWith(prefixSeparator: v as String? ?? '/'),
    ),
    FormFieldSpec<VoucherSeries>(
      key: 'startingNumber',
      wireKey: 'starting_number',
      label: 'Starting number',
      type: FieldType.int,
      getValue: (s) => s.startingNumber,
      setValue: (s, v) => s.copyWith(startingNumber: v as int? ?? 1),
    ),
    FormFieldSpec<VoucherSeries>(
      key: 'isDefault',
      wireKey: 'is_default',
      label: 'Default series',
      type: FieldType.bool,
      getValue: (s) => s.isDefault,
      setValue: (s, v) => s.copyWith(isDefault: v as bool?),
    ),
    FormFieldSpec<VoucherSeries>(
      key: 'requireApproval',
      wireKey: 'require_approval',
      label: 'Require approval',
      type: FieldType.bool,
      helperText:
          'On: Draft→Approved→Posted. Off: Approve → Posted. '
          'Create-as-Posted still books immediately.',
      getValue: (s) => s.requireApproval,
      setValue: (s, v) => s.copyWith(requireApproval: v as bool?),
    ),
  ],
  emptyEntity: () => const VoucherSeries(
    id: 0,
    voucherType: 'SalesInvoice',
    prefix: 'SI',
    displayName: '',
    companyId: 1,
  ),
);
