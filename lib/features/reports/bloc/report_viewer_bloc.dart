import 'package:algo_erp_front/core/reports/report_definition.dart';
import 'package:algo_erp_front/core/reports/report_repository.dart';
import 'package:algo_erp_front/features/reports/bloc/report_viewer_event.dart';
import 'package:algo_erp_front/features/reports/bloc/report_viewer_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportViewerBloc extends Bloc<ReportViewerEvent, ReportViewerState> {
  ReportViewerBloc({required this.definition, required this.repository})
    : super(const ReportViewerState()) {
    on<ReportViewerInitialized>(_onInitialized);
    on<ReportViewerParamChanged>(_onParamChanged);
    on<ReportViewerRunRequested>(_onRunRequested);
  }

  final ReportDefinition definition;
  final ReportRepository repository;

  void _onInitialized(
    ReportViewerInitialized event,
    Emitter<ReportViewerState> emit,
  ) {
    final now = DateTime.now();
    final textVals = <String, String>{};
    final dateVals = <String, DateTime?>{};

    for (final p in definition.params) {
      switch (p.type) {
        case ReportParamType.date:
          if (p.defaultToday) {
            dateVals[p.key] = DateTime(now.year, now.month, now.day);
          } else if (p.defaultMonthStart) {
            dateVals[p.key] = DateTime(now.year, now.month);
          } else {
            dateVals[p.key] = null;
          }
        case ReportParamType.text:
        case ReportParamType.intField:
          if (p.key == 'period') {
            textVals[p.key] =
                '${now.year}-${now.month.toString().padLeft(2, '0')}';
          } else {
            textVals[p.key] = '';
          }
      }
    }

    emit(state.copyWith(textValues: textVals, dateValues: dateVals));

    if (definition.autoRun) {
      add(const ReportViewerRunRequested());
    }
  }

  void _onParamChanged(
    ReportViewerParamChanged event,
    Emitter<ReportViewerState> emit,
  ) {
    if (event.value is DateTime?) {
      final updated = Map<String, DateTime?>.from(state.dateValues);
      updated[event.key] = event.value as DateTime?;
      emit(state.copyWith(dateValues: updated));
    } else {
      final updated = Map<String, String>.from(state.textValues);
      updated[event.key] = event.value?.toString() ?? '';
      emit(state.copyWith(textValues: updated));
    }
  }

  Future<void> _onRunRequested(
    ReportViewerRunRequested event,
    Emitter<ReportViewerState> emit,
  ) async {
    for (final p in definition.params) {
      if (p.required) {
        switch (p.type) {
          case ReportParamType.date:
            if (state.dateValues[p.key] == null) {
              emit(
                state.copyWith(
                  status: ReportViewerStatus.failure,
                  errorMessage: () => '${p.label} is required',
                ),
              );
              return;
            }
          case ReportParamType.text:
          case ReportParamType.intField:
            if ((state.textValues[p.key] ?? '').trim().isEmpty) {
              emit(
                state.copyWith(
                  status: ReportViewerStatus.failure,
                  errorMessage: () => '${p.label} is required',
                ),
              );
              return;
            }
        }
      }
    }

    emit(
      state.copyWith(
        status: ReportViewerStatus.loading,
        hasRun: true,
        rawData: () => null,
        failure: () => null,
      ),
    );

    final query = <String, String>{};
    for (final p in definition.params) {
      switch (p.type) {
        case ReportParamType.date:
          final d = state.dateValues[p.key];
          if (d != null) {
            query[p.key] = d.toIso8601String().split('T').first;
          }
        case ReportParamType.text:
        case ReportParamType.intField:
          final v = state.textValues[p.key]?.trim() ?? '';
          if (v.isNotEmpty) {
            query[p.key] = v;
          }
      }
    }

    final result = await repository.fetch(definition, query);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ReportViewerStatus.failure,
          failure: () => failure,
        ),
      ),
      (data) => emit(
        state.copyWith(status: ReportViewerStatus.success, rawData: () => data),
      ),
    );
  }
}
