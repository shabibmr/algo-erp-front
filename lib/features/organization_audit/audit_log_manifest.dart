import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/features/organization_audit/domain/audit_log.dart';

/// Read-only audit trail (no form).
final auditLogManifest = EntityManifest<AuditLog>(
  id: 'audit-log',
  label: 'Audit log',
  rbacModule: 'AuditLog',
  resourcePath: '/organization/audit-logs',
  listColumns: [
    FieldSpec<AuditLog>(
      key: 'timestamp',
      label: 'When',
      type: FieldType.text,
      cellValue: (l) => l.timestamp ?? '—',
    ),
    FieldSpec<AuditLog>(
      key: 'action',
      label: 'Action',
      type: FieldType.text,
      cellValue: (l) => l.action,
    ),
    FieldSpec<AuditLog>(
      key: 'status',
      label: 'Status',
      type: FieldType.text,
      cellValue: (l) => l.status,
    ),
    FieldSpec<AuditLog>(
      key: 'clientId',
      label: 'Client',
      type: FieldType.text,
      cellValue: (l) => l.clientId ?? '—',
    ),
    FieldSpec<AuditLog>(
      key: 'data',
      label: 'Data',
      type: FieldType.text,
      cellValue: (l) {
        final d = l.data;
        if (d == null || d.isEmpty) return '—';
        return d.length > 80 ? '${d.substring(0, 80)}…' : d;
      },
    ),
  ],
  searchFields: const ['action', 'status'],
  emptyMessage: 'No audit events yet — activity will appear here.',
);
