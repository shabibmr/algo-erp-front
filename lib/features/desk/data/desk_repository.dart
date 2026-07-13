import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/desk/domain/dashboard_summary.dart';
import 'package:algo_erp_front/features/desk/domain/dashboard_trend_point.dart';
import 'package:algo_erp_front/features/desk/domain/desk_alerts.dart';

/// Online desk feeds: dashboard KPIs + action alerts.
class DeskRepository {
  DeskRepository(this._client);

  final DioClient _client;

  Future<Result<DashboardSummary>> fetchDashboard({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return safeCall(() async {
      final end = endDate ?? DateTime.now();
      final start = startDate ?? DateTime(end.year, end.month);
      final res = await _client.dio.get<Object?>(
        '/reports/dashboard',
        queryParameters: {
          'start_date': start.toIso8601String().split('T').first,
          'end_date': end.toIso8601String().split('T').first,
        },
      );
      final envelope = decodeApiResponse<Map<String, dynamic>>(
        res.data,
        (j) => Map<String, dynamic>.from(j! as Map),
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected dashboard data');
      }
      return DashboardSummary.fromJson(data);
    });
  }

  Future<Result<List<DashboardTrendPoint>>> fetchTrend({int months = 6}) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>(
        '/reports/dashboard/trend',
        queryParameters: {'months': months},
      );
      final envelope = decodeApiResponse<Map<String, dynamic>>(
        res.data,
        (j) => Map<String, dynamic>.from(j! as Map),
      );
      final points = envelope.data?['points'];
      if (points is! List) {
        throw const FormatException('Expected trend points');
      }
      return points
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) => DashboardTrendPoint.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(growable: false);
    });
  }

  Future<Result<DeskAlerts>> fetchAlerts() {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>('/reports/alerts');
      final envelope = decodeApiResponse<Map<String, dynamic>>(
        res.data,
        (j) => Map<String, dynamic>.from(j! as Map),
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected alerts data');
      }
      return DeskAlerts.fromJson(data);
    });
  }
}

DeskRepository createDeskRepository(DioClient client) => DeskRepository(client);
