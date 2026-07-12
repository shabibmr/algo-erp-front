import 'package:equatable/equatable.dart';

class AuditLogDto extends Equatable {
  const AuditLogDto({
    required this.id,
    required this.action,
    required this.status,
    this.timestamp,
    this.data,
    this.clientId,
  });

  factory AuditLogDto.fromJson(Map<String, dynamic> json) => AuditLogDto(
    id: json['id'] as int? ?? json['_id'] as int? ?? 0,
    action: json['action'] as String? ?? '',
    status: json['status'] as String? ?? '',
    timestamp: json['timestamp']?.toString(),
    data: json['data'] as String?,
    clientId: json['client_id'] as String?,
  );

  final int id;
  final String action;
  final String status;
  final String? timestamp;
  final String? data;
  final String? clientId;

  @override
  List<Object?> get props => [id, action, status, timestamp, data, clientId];
}
