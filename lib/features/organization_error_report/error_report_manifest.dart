import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/features/organization_error_report/domain/error_report.dart';

/// Error reports — create + list (view fields read-only on create form).
final errorReportManifest = EntityManifest<ErrorReport>(
  id: 'error-report',
  label: 'Error report',
  rbacModule: 'ErrorReporting',
  resourcePath: '/organization/error-reports',
  listColumns: [
    FieldSpec<ErrorReport>(
      key: 'timeStamp',
      label: 'When',
      type: FieldType.text,
      cellValue: (e) => e.timeStamp ?? '—',
    ),
    FieldSpec<ErrorReport>(
      key: 'tablename',
      label: 'Table',
      type: FieldType.text,
      cellValue: (e) => e.tablename.isEmpty ? '—' : e.tablename,
    ),
    FieldSpec<ErrorReport>(
      key: 'error',
      label: 'Error',
      type: FieldType.text,
      cellValue: (e) {
        final t = e.error;
        return t.length > 100 ? '${t.substring(0, 100)}…' : t;
      },
    ),
  ],
  formFields: [
    FormFieldSpec<ErrorReport>(
      key: 'error',
      wireKey: 'error',
      label: 'Error',
      type: FieldType.text,
      required: true,
      getValue: (e) => e.error,
      setValue: (e, v) => e.copyWith(error: v as String? ?? ''),
    ),
    FormFieldSpec<ErrorReport>(
      key: 'tablename',
      wireKey: 'tablename',
      label: 'Table name',
      type: FieldType.text,
      getValue: (e) => e.tablename,
      setValue: (e, v) => e.copyWith(tablename: v as String? ?? ''),
    ),
    FormFieldSpec<ErrorReport>(
      key: 'query',
      wireKey: 'query',
      label: 'Query / context',
      type: FieldType.text,
      getValue: (e) => e.query,
      setValue: (e, v) => e.copyWith(query: v as String? ?? ''),
    ),
    FormFieldSpec<ErrorReport>(
      key: 'clientId',
      wireKey: 'client_id',
      label: 'Client id',
      type: FieldType.text,
      getValue: (e) => e.clientId,
      setValue: (e, v) => e.copyWith(clientId: v as String?),
    ),
  ],
  emptyEntity: () => const ErrorReport(id: 0, error: ''),
  supportsUpdate: false,
  supportsDelete: false,
  hardDelete: true,
  emptyMessage: 'No client error reports captured yet.',
);
