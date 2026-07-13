import 'package:algo_erp_front/core/reports/report_catalog.dart';
import 'package:algo_erp_front/core/reports/report_definition.dart';
import 'package:algo_erp_front/features/reports/bloc/reports_hub_event.dart';
import 'package:algo_erp_front/features/reports/bloc/reports_hub_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportsHubBloc extends Bloc<ReportsHubEvent, ReportsHubState> {
  ReportsHubBloc() : super(const ReportsHubState()) {
    on<ReportsHubInitialized>(_onInitialized);
    on<ReportsHubCategorySelected>(_onCategorySelected);
    on<ReportsHubSearchChanged>(_onSearchChanged);
  }

  void _onInitialized(
    ReportsHubInitialized event,
    Emitter<ReportsHubState> emit,
  ) {
    _filterAndEmit(state.selectedCategory, state.searchQuery, emit);
  }

  void _onCategorySelected(
    ReportsHubCategorySelected event,
    Emitter<ReportsHubState> emit,
  ) {
    _filterAndEmit(event.category, state.searchQuery, emit);
  }

  void _onSearchChanged(
    ReportsHubSearchChanged event,
    Emitter<ReportsHubState> emit,
  ) {
    _filterAndEmit(state.selectedCategory, event.searchQuery, emit);
  }

  void _filterAndEmit(
    ReportCategory? category,
    String searchQuery,
    Emitter<ReportsHubState> emit,
  ) {
    final query = searchQuery.trim().toLowerCase();
    final filtered = ReportCatalog.all.where((r) {
      final matchesCat = category == null || r.category == category;
      if (!matchesCat) return false;
      if (query.isEmpty) return true;
      final titleMatch = r.title.toLowerCase().contains(query);
      final endpointMatch = r.endpoint.toLowerCase().contains(query);
      final moduleMatch = (r.requiredModule ?? '').toLowerCase().contains(
        query,
      );
      final categoryMatch = r.category.displayName.toLowerCase().contains(
        query,
      );
      return titleMatch || endpointMatch || moduleMatch || categoryMatch;
    }).toList();

    emit(
      ReportsHubState(
        selectedCategory: category,
        searchQuery: searchQuery,
        reports: filtered,
      ),
    );
  }
}
