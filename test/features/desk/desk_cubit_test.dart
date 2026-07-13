import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/desk/data/desk_repository.dart';
import 'package:algo_erp_front/features/desk/domain/dashboard_summary.dart';
import 'package:algo_erp_front/features/desk/domain/dashboard_trend_point.dart';
import 'package:algo_erp_front/features/desk/domain/desk_alerts.dart';
import 'package:algo_erp_front/features/desk/presentation/cubit/desk_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeskRepository extends Mock implements DeskRepository {}

void main() {
  late _MockDeskRepository repo;

  const dashboard = DashboardSummary(
    startDate: null,
    endDate: null,
    salesCount: 4,
    purchaseCount: 2,
    cashPosition: 100,
    bankPosition: 50,
    topCustomers: [],
  );
  const alerts = DeskAlerts(expiringDocuments: [], overdueBills: []);
  const trend = [
    DashboardTrendPoint(
      month: '2026-06',
      salesCount: 3,
      purchaseCount: 1,
      cashPosition: 80,
      bankPosition: 40,
    ),
  ];

  setUp(() {
    repo = _MockDeskRepository();
  });

  DeskCubit build() => DeskCubit(repo);

  blocTest<DeskCubit, DeskState>(
    'load() succeeds → dashboard, alerts and trend all populated',
    setUp: () {
      when(
        () => repo.fetchDashboard(),
      ).thenAnswer((_) async => const Right(dashboard));
      when(
        () => repo.fetchAlerts(),
      ).thenAnswer((_) async => const Right(alerts));
      when(() => repo.fetchTrend()).thenAnswer((_) async => const Right(trend));
    },
    build: build,
    act: (cubit) => cubit.load(),
    skip: 1,
    expect: () => [
      isA<DeskState>()
          .having((s) => s.loading, 'loading', false)
          .having((s) => s.dashboard, 'dashboard', dashboard)
          .having((s) => s.alerts, 'alerts', alerts)
          .having((s) => s.trend, 'trend', trend),
    ],
  );

  blocTest<DeskCubit, DeskState>(
    'trend fails but dashboard/alerts still load',
    setUp: () {
      when(
        () => repo.fetchDashboard(),
      ).thenAnswer((_) async => const Right(dashboard));
      when(
        () => repo.fetchAlerts(),
      ).thenAnswer((_) async => const Right(alerts));
      when(
        () => repo.fetchTrend(),
      ).thenAnswer((_) async => const Left(Failure.network('offline')));
    },
    build: build,
    act: (cubit) => cubit.load(),
    skip: 1,
    expect: () => [
      isA<DeskState>()
          .having((s) => s.dashboard, 'dashboard', dashboard)
          .having((s) => s.alerts, 'alerts', alerts)
          .having((s) => s.trend, 'trend', const <DashboardTrendPoint>[])
          .having((s) => s.trendFailure, 'trendFailure', isNotNull),
    ],
  );
}
