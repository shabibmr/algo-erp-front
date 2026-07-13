import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/reports/report_definition.dart';

/// Fetches a report by [ReportDefinition.endpoint] + query params.
class ReportRepository {
  ReportRepository(this._client);

  final DioClient _client;

  Future<Result<Object?>> fetch(
    ReportDefinition def,
    Map<String, String> params,
  ) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>(
        def.endpoint,
        queryParameters: params.isEmpty ? null : params,
      );
      final envelope = decodeApiResponse<Object?>(res.data, (j) => j);
      return envelope.data;
    });
  }
}

ReportRepository createReportRepository(DioClient client) =>
    ReportRepository(client);
