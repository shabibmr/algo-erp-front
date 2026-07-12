import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/organization_audit/data/audit_log_dto.dart';
import 'package:algo_erp_front/features/organization_audit/domain/audit_log.dart';

class AuditLogMapper implements Mapper<AuditLogDto, AuditLog> {
  const AuditLogMapper();

  @override
  AuditLog toEntity(AuditLogDto dto) => AuditLog(
    id: dto.id,
    action: dto.action,
    status: dto.status,
    timestamp: dto.timestamp,
    data: dto.data,
    clientId: dto.clientId,
  );

  @override
  AuditLogDto toDto(AuditLog entity) => AuditLogDto(
    id: entity.id,
    action: entity.action,
    status: entity.status,
    timestamp: entity.timestamp,
    data: entity.data,
    clientId: entity.clientId,
  );
}
