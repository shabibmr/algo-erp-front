import 'package:algo_erp_front/core/data/remote_data_source.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/features/organization_error_report/data/error_report_dto.dart';
import 'package:algo_erp_front/features/organization_error_report/data/error_report_mapper.dart';
import 'package:algo_erp_front/features/organization_error_report/domain/error_report.dart';
import 'package:fpdart/fpdart.dart';

/// List + create. No get/update/delete routes.
class ErrorReportRepository implements Repository<ErrorReport, int> {
  ErrorReportRepository(this._client, {ErrorReportMapper? mapper})
    : _mapper = mapper ?? const ErrorReportMapper();

  final DioClient _client;
  final ErrorReportMapper _mapper;

  static const _path = '/organization/error-reports';

  @override
  Future<Result<Paginated<ErrorReport>>> list(PageQuery query) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>(
        _path,
        queryParameters: {'page': query.page, 'limit': query.limit},
      );
      final envelope = decodeApiResponse<Object?>(res.data, (j) => j);
      final data = envelope.data;
      List<dynamic> items;
      PaginationMeta meta;
      if (data is Map<String, dynamic> && data['items'] is List) {
        items = data['items'] as List<dynamic>;
        final m = data['meta'] as Map<String, dynamic>?;
        meta = PaginationMeta(
          total: m?['total'] as int? ?? items.length,
          page: m?['page'] as int? ?? query.page,
          limit: m?['limit'] as int? ?? query.limit,
          totalPages: m?['totalPages'] as int? ?? 1,
        );
      } else if (data is List) {
        items = data;
        meta = PaginationMeta(
          total: items.length,
          page: 1,
          limit: items.length,
          totalPages: 1,
        );
      } else {
        throw const FormatException('Expected error report list');
      }
      return Paginated<ErrorReport>(
        items: [
          for (final raw in items)
            if (raw is Map<String, dynamic>)
              _mapper.toEntity(ErrorReportDto.fromJson(raw)),
        ],
        meta: meta,
      );
    });
  }

  @override
  Future<Result<ErrorReport>> getById(int id) {
    return Future.value(
      const Left(Failure.unknown('Error reports have no get-by-id route')),
    );
  }

  @override
  Future<Result<ErrorReport>> create(ErrorReport entity) {
    return safeCall(() async {
      final res = await _client.dio.post<Object?>(
        _path,
        data: _mapper.toDto(entity).toJson(),
      );
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected created error report');
      }
      return _mapper.toEntity(ErrorReportDto.fromJson(data));
    });
  }

  @override
  Future<Result<ErrorReport>> update(int id, ErrorReport entity) {
    return Future.value(
      const Left(Failure.unknown('Error reports cannot be updated')),
    );
  }

  @override
  Future<Result<Unit>> delete(int id) {
    return Future.value(
      const Left(Failure.unknown('Error reports cannot be deleted')),
    );
  }
}
