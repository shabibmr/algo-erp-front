import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/desk/data/desk_repository.dart';
import 'package:algo_erp_front/features/desk/domain/dashboard_summary.dart';
import 'package:algo_erp_front/features/desk/domain/dashboard_trend_point.dart';
import 'package:algo_erp_front/features/desk/domain/desk_alerts.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeskState extends Equatable {
  const DeskState({
    this.loading = true,
    this.dashboard,
    this.alerts,
    this.trend = const [],
    this.dashboardFailure,
    this.alertsFailure,
    this.trendFailure,
  });

  final bool loading;
  final DashboardSummary? dashboard;
  final DeskAlerts? alerts;
  final List<DashboardTrendPoint> trend;
  final Failure? dashboardFailure;
  final Failure? alertsFailure;
  final Failure? trendFailure;

  @override
  List<Object?> get props => [
    loading,
    dashboard,
    alerts,
    trend,
    dashboardFailure,
    alertsFailure,
    trendFailure,
  ];
}

class DeskCubit extends Cubit<DeskState> {
  DeskCubit(this._repo) : super(const DeskState());

  final DeskRepository _repo;

  Future<void> load() async {
    emit(const DeskState());
    final dashResult = await _repo.fetchDashboard();
    final alertsResult = await _repo.fetchAlerts();
    final trendResult = await _repo.fetchTrend();

    emit(
      DeskState(
        loading: false,
        dashboard: dashResult.fold((_) => null, (d) => d),
        alerts: alertsResult.fold((_) => null, (a) => a),
        trend: trendResult.fold((_) => const [], (t) => t),
        dashboardFailure: dashResult.fold((f) => f, (_) => null),
        alertsFailure: alertsResult.fold((f) => f, (_) => null),
        trendFailure: trendResult.fold((f) => f, (_) => null),
      ),
    );
  }
}
