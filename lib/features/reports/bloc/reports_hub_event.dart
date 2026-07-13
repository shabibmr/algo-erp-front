import 'package:algo_erp_front/core/reports/report_definition.dart';
import 'package:equatable/equatable.dart';

sealed class ReportsHubEvent extends Equatable {
  const ReportsHubEvent();

  @override
  List<Object?> get props => [];
}

final class ReportsHubInitialized extends ReportsHubEvent {
  const ReportsHubInitialized();
}

final class ReportsHubCategorySelected extends ReportsHubEvent {
  const ReportsHubCategorySelected(this.category);
  final ReportCategory? category;

  @override
  List<Object?> get props => [category];
}

final class ReportsHubSearchChanged extends ReportsHubEvent {
  const ReportsHubSearchChanged(this.searchQuery);
  final String searchQuery;

  @override
  List<Object?> get props => [searchQuery];
}
