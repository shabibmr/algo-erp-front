import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/organization_error_report/data/error_report_dto.dart';
import 'package:algo_erp_front/features/organization_error_report/domain/error_report.dart';

class ErrorReportMapper implements Mapper<ErrorReportDto, ErrorReport> {
  const ErrorReportMapper();

  @override
  ErrorReport toEntity(ErrorReportDto dto) => ErrorReport(
    id: dto.id,
    error: dto.error,
    tablename: dto.tablename,
    query: dto.query,
    clientId: dto.clientId,
    timeStamp: dto.timeStamp,
  );

  @override
  ErrorReportDto toDto(ErrorReport entity) => ErrorReportDto(
    id: entity.id,
    error: entity.error,
    tablename: entity.tablename,
    query: entity.query,
    clientId: entity.clientId,
    timeStamp: entity.timeStamp,
  );
}
