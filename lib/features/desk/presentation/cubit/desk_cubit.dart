import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/desk/data/desk_repository.dart';
import 'package:algo_erp_front/features/desk/domain/dashboard_summary.dart';
import 'package:algo_erp_front/features/desk/domain/desk_alerts.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeskState extends Equatable {
  const DeskState({
    this.loading = true,
    this.dashboard,
    this.alerts,
    this.dashboardFailure,
    this.alertsFailure,
  });

  final bool loading;
  final DashboardSummary? dashboard;
  final DeskAlerts? alerts;
  final Failure? dashboardFailure;
  final Failure? alertsFailure;

  @override
  List<Object?> get props => [
    loading,
    dashboard,
    alerts,
    dashboardFailure,
    alertsFailure,
  ];
}

class DeskCubit extends Cubit<DeskState> {
  DeskCubit(this._repo) : super(const DeskState());

  final DeskRepository _repo;

  Future<void> load() async {
    emit(const DeskState());
    final dashResult = await _repo.fetchDashboard();
    final alertsResult = await _repo.fetchAlerts();

    emit(
      DeskState(
        loading: false,
        dashboard: dashResult.fold((_) => null, (d) => d),
        alerts: alertsResult.fold((_) => null, (a) => a),
        dashboardFailure: dashResult.fold((f) => f, (_) => null),
        alertsFailure: alertsResult.fold((f) => f, (_) => null),
      ),
    );
  }
}
