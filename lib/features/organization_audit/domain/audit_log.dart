import 'package:equatable/equatable.dart';

/// Read-only audit trail row from `/organization/audit-logs`.
class AuditLog extends Equatable {
  const AuditLog({
    required this.id,
    required this.action,
    required this.status,
    this.timestamp,
    this.data,
    this.clientId,
  });

  final int id;
  final String action;
  final String status;
  final String? timestamp;
  final String? data;
  final String? clientId;

  @override
  List<Object?> get props => [id, action, status, timestamp, data, clientId];
}
