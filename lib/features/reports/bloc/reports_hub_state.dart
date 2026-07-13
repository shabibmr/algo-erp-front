import 'package:algo_erp_front/core/reports/report_definition.dart';
import 'package:equatable/equatable.dart';

final class ReportsHubState extends Equatable {
  const ReportsHubState({
    this.selectedCategory,
    this.searchQuery = '',
    this.reports = const [],
  });

  final ReportCategory? selectedCategory;
  final String searchQuery;
  final List<ReportDefinition> reports;

  List<ReportCategory> get activeCategories {
    return ReportCategory.values.where((cat) {
      return reports.any((r) => r.category == cat);
    }).toList();
  }

  List<ReportDefinition> reportsForCategory(ReportCategory category) {
    return reports.where((r) => r.category == category).toList();
  }

  ReportsHubState copyWith({
    ReportCategory? Function()? selectedCategory,
    String? searchQuery,
    List<ReportDefinition>? reports,
  }) {
    return ReportsHubState(
      selectedCategory: selectedCategory != null
          ? selectedCategory()
          : this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      reports: reports ?? this.reports,
    );
  }

  @override
  List<Object?> get props => [selectedCategory, searchQuery, reports];
}
